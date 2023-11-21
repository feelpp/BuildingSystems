import pytest
import sys
import os
import spdlog as spd
import pandas as pd

from pathlib import Path
from xvfbwrapper import Xvfb

dymola = "/opt/dymola-2023-x86_64/"
dymolapath = "/usr/local/bin/dymola-2023-x86_64"
dymolaegg = "Modelica/Library/python_interface/dymola.egg"
logger = spd.ConsoleLogger('Logger', False, True, True)
has_dymola=False

try:
    sys.path.append(str(Path(dymola) / Path(dymolaegg)))
    logger.info("add {} to sys path".format(Path(dymola) / Path(dymolaegg)))
    if not (Path(dymola) / Path(dymolaegg)).is_file():
        logger.error("dymola egg {} does not exist".format(
            Path(dymola) / Path(dymolaegg)))
    import dymola
    from dymola.dymola_interface import DymolaInterface
    from dymola.dymola_exception import DymolaException
    has_dymola = True
except ImportError as e:
    logger.info(
        "dymola module is not available, has_dymola: {}".format(has_dymola))
    pass  # module doesn't exist, deal with it.
if not has_dymola:
    logger.error("dymola is not available, tests cannot be executed")
    sys.exit()

# data processing
modelsDf = pd.read_json("tests/models.json")
modelsList = []
for tup in modelsDf['Buildings'].items():
    domain, subList = tup
    prefix = 'BuildingSystems.Buildings.' + domain + '.'
    liste = tup[1]
    for elt in liste:
        modelsList.append(prefix+elt)

@pytest.mark.parametrize("model", modelsList)
def test_checkModel(model):

    # launch a display server
    vdisplay = Xvfb()
    vdisplay.start()

    # start Dymola
    dymApp = DymolaInterface(dymolapath=dymolapath, showwindow=False)

    # load package
    isOpen = dymApp.openModel(os.getcwd() + "/BuildingSystems/package.mo", changeDirectory=False)
    if isOpen is False:
        logger.error("dymola failed to load the BuildingSystems package")
        dymApp.close()
        vdisplay.stop()
        sys.exit()

    result = dymApp.checkModel(problem=model)
    if result is False:
        log = dymApp.getLastErrorLog()
        logger.error("{}".format(log))

    # close Dymola and display server
    dymApp.close()
    vdisplay.stop()

    assert(result == True)