from multiprocessing import Process
from xvfbwrapper import Xvfb
from pathlib import Path
import platform, sys, os
import spdlog as spd
import shutil
import pytest


def moSim(mo, odir, loggerName,
          dymola="/opt/dymola-2023-x86_64/", 
          dymolapath="/usr/local/bin/dymola-2023-x86_64", 
          dymolaegg="Modelica/Library/python_interface/dymola.egg", 
          verbose=True):
    """
    moSim simulates a modelica model
    """                          
    logger = spd.ConsoleLogger(loggerName, True, True, True)
    has_dymola=False

    # Change PYTHONPATH
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
            "dymola module is not available, has_dymola: {}".format(has_dymola))
        pass  # module doesn't exist, deal with it.
    if not has_dymola:
        logger.error("dymola is not available, moSim failed")
        return False
    vdisplay = Xvfb()
    vdisplay.start()
    osString = platform.system()
    isWindows = osString.startswith("Win")
        
    dymola = None
    try:
        # Instantiate the Dymola interface and start Dymola
        dymola = DymolaInterface(dymolapath=dymolapath, showwindow=False)
        
        dymola.openModel(mo, changeDirectory=False)
        
        # Find the package the model belongs to
        with open(mo, "r") as f:
            lines = f.readlines()
        for line in lines:
            if line.strip().startswith('within '):
                packageName = line.split(' ')[1][:-2]
            else:
                pass
        moModel = packageName+"."+Path(mo).stem

        # Change working directory
        dymola.cd(str(odir))
        
        result = dymola.simulateModel(moModel, 
                                    startTime = 0, 
                                    stopTime = 7200, 
                                    outputInterval = 3600,
                                    resultFile = os.path.dirname(odir)+"/"+str(Path(mo).stem))
        if not result:
            log = dymola.getLastErrorLog()
            logger.error("Simulation failed. Below is the translation log.")
            logger.info(log)
            return
        if verbose:
            logger.info("{} model successfully simulated".format(mo))  
                  
    except DymolaException as ex:
        logger.error(str(ex))
        logger.info("Dymola exception") 
        vdisplay.stop()
        
    except KeyboardInterrupt:
        print(dymola)
        if dymola is not None:
            logger.info("KeyboardInterrupt") 
            dymola.close()
            dymola = None
            vdisplay.stop()
        print(dymola)
            
    finally:
        if dymola is not None:
            dymola.close()
            dymola = None
            vdisplay.stop()
            
            
class CheckModelica():
    @pytest.fixture(autouse=True)
    def setup(self, tmpdir):
        self.tmpdir = tmpdir
    
    def check_buildings(self):
        """ This test is to make sure that simulation of the building model examples run normally and produce result files.
            The simulation results are not checked.
        """
        buildingModels = ["BuildingSystems/Buildings/Examples/Building1Zone0D.mo",
                          "BuildingSystems/Buildings/Examples/BuildingHygroThermal1Zone1D.mo",
                          "BuildingSystems/Buildings/Examples/BuildingThermal1Zone1D.mo",
                          "BuildingSystems/Buildings/Examples/BuildingThermal1Zone1DBox.mo",
                          "BuildingSystems/Buildings/Examples/BuildingThermal1Zone1DCylinder.mo",
                          "BuildingSystems/Buildings/Examples/BuildingThermal4Zones1DAirpaths.mo",
                          "BuildingSystems/Buildings/Examples/BuildingThermalMultiZone.mo"]
    
        procs = []
        proc = Process(target=moSim)  # instantiating without any argument
        procs.append(proc)
        proc.start()

        # instantiating process with arguments
        for mo in buildingModels:
            odir = Path(self.tmpdir)/Path(Path(mo).stem)
            if odir.is_dir() is False:
                os.mkdir(odir)
            proc = Process(target=moSim, args=(mo, odir, "buildingsLogger", ))
            procs.append(proc)
            proc.start()

        # complete the processes
        finalRes = []
        for proc in procs:
            proc.join()
            
        outputFiles = []
        for file in os.listdir(self.tmpdir):
            if file.endswith('.mat'):
                outputFiles.append(file)
                
        assert(len(outputFiles) == 7)
        

    def check_districts(self):
        """ This test is to make sure that simulation of the districts model examples run normally and produce result files.
            The simulation results are not checked.
        """
        districtModels = ["BuildingSystems/Applications/DistrictSimulation/DistrictBerlinKreuzberg.mo",
                            # "BuildingSystems/Applications/DistrictSimulation/HCBC_DHN.mo",
                            "BuildingSystems/Applications/DistrictSimulation/HCBC.mo"]
        
        procs = []
        proc = Process(target=moSim)  # instantiating without any argument
        procs.append(proc)
        proc.start()

        # instantiating process with arguments
        for mo in districtModels:
            odir = Path(self.tmpdir)/Path(Path(mo).stem)
            if odir.is_dir() is False:
                os.mkdir(odir)
            proc = Process(target=moSim, args=(mo, odir, "buildingsLogger", ))
            procs.append(proc)
            proc.start()

        # complete the processes
        finalRes = []
        for proc in procs:
            proc.join()
            
        outputFiles = []
        for file in os.listdir(self.tmpdir):
            if file.endswith('.mat'):
                outputFiles.append(file)
    
        assert(len(outputFiles) == 2)
        