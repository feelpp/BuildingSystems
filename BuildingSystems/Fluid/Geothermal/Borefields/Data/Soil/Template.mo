within BuildingSystems.Fluid.Geothermal.Borefields.Data.Soil;
record Template
  "Template for soil data records"
  extends Modelica.Icons.Record;
  parameter Modelica.SIunits.ThermalConductivity kSoi
    "Thermal conductivity of the soil material";
  parameter Modelica.SIunits.SpecificHeatCapacity cSoi
    "Specific heat capacity of the soil material";
  parameter Modelica.SIunits.Density dSoi(displayUnit="kg/m3")
    "Density of the soil material";
  parameter Boolean steadyState = (cSoi < Modelica.Constants.eps or dSoi < Modelica.Constants.eps)
    "Flag, if true, then material is computed using steady-state heat conduction"
    annotation(Evaluate=true);
  final parameter Modelica.SIunits.ThermalDiffusivity aSoi=kSoi/(dSoi*cSoi)
    "Heat diffusion coefficient of the soil material";
  annotation (
  defaultComponentPrefixes="parameter",
  defaultComponentName="soiDat",
Documentation(
info="<html>
<p>
This record is a template for the records in
<a href=\"modelica://BuildingSystems.Fluid.Geothermal.Borefields.Data.Soil\">
BuildingSystems.Fluid.Geothermal.Borefields.Data.Soil</a>.
</p>
</html>",
revisions="<html>
<ul>
<li>
July 15, 2018, by Michael Wetter:<br/>
Revised implementation, added <code>defaultComponentPrefixes</code> and
<code>defaultComponentName</code>.
Corrected check of real variable against zero which is not allowed in Modelica.
</li>
<li>
June28, 2018, by Damien Picard:<br/>
First implementation.
</li>
</ul>
</html>"));
end Template;
