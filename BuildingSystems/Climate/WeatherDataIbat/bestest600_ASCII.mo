within BuildingSystems.Climate.WeatherDataIbat;
block bestest600_ASCII
  extends BuildingSystems.Climate.WeatherData.BaseClasses.WeatherDataFileASCII(
  info="Source: ASHRAE 140-2020",
  filNam=Modelica.Utilities.Files.loadResource("modelica://BuildingSystems/Climate/weather/bestest600.txt"),
  final tabNam="tab1",
  final timeFac = 1.0/3600.0,
  final deltaTime = 3600.0,
  final columns={
    2, // beam horizontal radiation
    3, // diffuse horizontal radiation
    4, // air temperature
    5, // wind speed
    6, // wind direction
    7, // relative humidity
    8  // cloud cover
    },
  final scaleFac = {1.0,1.0,1.0,1.0,1.0,0.01,0.01},
  final latitudeDeg = 39.883,
  final longitudeDeg = -104.65,
  final longitudeDeg_0 = 1.0);
  annotation(Documentation(info="<html>source: meteoblue</html>"));
end bestest600_ASCII;