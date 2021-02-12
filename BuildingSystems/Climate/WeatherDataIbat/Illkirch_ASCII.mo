within BuildingSystems.Climate.WeatherDataIbat;
block Illkirch_ASCII
  extends BuildingSystems.Climate.WeatherData.BaseClasses.WeatherDataFileASCII(
  info="Source: meteoblue",
  filNam=Modelica.Utilities.Files.loadResource("modelica://BuildingSystems/Climate/weather/ibat_Illkirch_test.txt"),
  final tabNam="tab1",
  final timeFac = 1.0/3600.0,
  final deltaTime = 1800.0,
  final columns={
    7, // beam horizontal radiation
    8, // diffuse horizontal radiation
    2, // air temperature
    4, // wind speed
    5, // wind direction
    3, // relative humidity
    6  // cloud cover
    },
  final scaleFac = {1.0,1.0,1.0,1.0,1.0,0.01,0.01},
  final latitudeDeg = 48.53,
  final longitudeDeg = 7.72,
  final longitudeDeg_0 = 1.0);
  annotation(Documentation(info="<html>source: meteoblue</html>"));
end Illkirch_ASCII;