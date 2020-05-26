within BuildingSystems.Controls.Continuous;
block LimPID
  "P, PI, PD, and PID controller with limited output, anti-windup compensation and setpoint weighting"

  extends Modelica.Blocks.Interfaces.SVcontrol;
  output Real controlError = u_s - u_m
    "Control error (set point - measurement)";

  parameter Modelica.Blocks.Types.SimpleController controllerType=
         Modelica.Blocks.Types.SimpleController.PID "Type of controller";
  parameter Real k(min=0) = 1 "Gain of controller";
  parameter Modelica.SIunits.Time Ti(min=Modelica.Constants.small)=0.5
    "Time constant of Integrator block" annotation (Dialog(enable=
          controllerType == Modelica.Blocks.Types.SimpleController.PI or
          controllerType == Modelica.Blocks.Types.SimpleController.PID));
  parameter Modelica.SIunits.Time Td(min=0)=0.1
    "Time constant of Derivative block" annotation (Dialog(enable=
          controllerType == Modelica.Blocks.Types.SimpleController.PD or
          controllerType == Modelica.Blocks.Types.SimpleController.PID));
  parameter Real yMax(start=1)=1 "Upper limit of output";
  parameter Real yMin=0 "Lower limit of output";
  parameter Real wp(min=0) = 1 "Set-point weight for Proportional block (0..1)";
  parameter Real wd(min=0) = 0 "Set-point weight for Derivative block (0..1)"
       annotation(Dialog(enable=controllerType==.Modelica.Blocks.Types.SimpleController.PD or
                                controllerType==.Modelica.Blocks.Types.SimpleController.PID));
  parameter Real Ni(min=100*Modelica.Constants.eps) = 0.9
    "Ni*Ti is time constant of anti-windup compensation"
     annotation(Dialog(enable=controllerType==.Modelica.Blocks.Types.SimpleController.PI or
                              controllerType==.Modelica.Blocks.Types.SimpleController.PID));
  parameter Real Nd(min=100*Modelica.Constants.eps) = 10
    "The higher Nd, the more ideal the derivative block"
       annotation(Dialog(enable=controllerType==.Modelica.Blocks.Types.SimpleController.PD or
                                controllerType==.Modelica.Blocks.Types.SimpleController.PID));
  parameter Modelica.Blocks.Types.InitPID initType= Modelica.Blocks.Types.InitPID.DoNotUse_InitialIntegratorState
    "Type of initialization (1: no init, 2: steady state, 3: initial state, 4: initial output)"
                                     annotation(Evaluate=true,
      Dialog(group="Initialization"));
      // Removed as the Limiter block no longer uses this parameter.
      // parameter Boolean limitsAtInit = true
      //  "= false, if limits are ignored during initialization"
      // annotation(Evaluate=true, Dialog(group="Initialization"));
  parameter Real xi_start=0
    "Initial or guess value value for integrator output (= integrator state)"
    annotation (Dialog(group="Initialization",
                enable=controllerType==.Modelica.Blocks.Types.SimpleController.PI or
                       controllerType==.Modelica.Blocks.Types.SimpleController.PID));
  parameter Real xd_start=0
    "Initial or guess value for state of derivative block"
    annotation (Dialog(group="Initialization",
                         enable=controllerType==.Modelica.Blocks.Types.SimpleController.PD or
                                controllerType==.Modelica.Blocks.Types.SimpleController.PID));
  parameter Real y_start=0 "Initial value of output"
    annotation(Dialog(enable=initType == Modelica.Blocks.Types.InitPID.InitialOutput, group=
          "Initialization"));
  parameter Boolean strict=true "= true, if strict limits with noEvent(..)"
    annotation (Evaluate=true, choices(checkBox=true), Dialog(tab="Advanced"));

  parameter Boolean reverseAction = false
    "Set to true for throttling the water flow rate through a cooling coil controller";

  parameter BuildingSystems.Types.Reset reset = BuildingSystems.Types.Reset.Disabled
    "Type of controller output reset"
    annotation(Evaluate=true, Dialog(group="Integrator reset"));

  parameter Real y_reset=xi_start
    "Value to which the controller output is reset if the boolean trigger has a rising edge, used if reset == BuildingSystems.Types.Reset.Parameter"
    annotation(Dialog(enable=reset == BuildingSystems.Types.Reset.Parameter,
                      group="Integrator reset"));

  Modelica.Blocks.Interfaces.BooleanInput trigger if
       reset <> BuildingSystems.Types.Reset.Disabled
    "Resets the controller output when trigger becomes true"
    annotation (Placement(transformation(extent={{-20,-20},{20,20}},
        rotation=90,
        origin={-80,-120})));

  Modelica.Blocks.Interfaces.RealInput y_reset_in if
       reset == BuildingSystems.Types.Reset.Input
    "Input signal for state to which integrator is reset, enabled if reset = BuildingSystems.Types.Reset.Input"
    annotation (Placement(transformation(extent={{-140,-100},{-100,-60}})));

  Modelica.Blocks.Math.Add addP(k1=revAct*wp, k2=-revAct) "Adder for P gain"
   annotation (Placement(
        transformation(extent={{-80,40},{-60,60}})));
  Modelica.Blocks.Math.Add addD(k1=revAct*wd, k2=-revAct) if with_D
    "Adder for D gain"
    annotation (Placement(
        transformation(extent={{-80,-10},{-60,10}})));
  Modelica.Blocks.Math.Gain P(k=1) "Proportional term"
    annotation (Placement(transformation(extent={{-40,40},{-20,60}})));
  Utilities.Math.IntegratorWithReset I(
    final reset=if reset == BuildingSystems.Types.Reset.Disabled then reset else BuildingSystems.Types.Reset.Input,
    final y_reset=y_reset,
    final k=unitTime/Ti,
    final y_start=xi_start,
    final initType=if initType == Modelica.Blocks.Types.InitPID.SteadyState then
        Modelica.Blocks.Types.Init.SteadyState
             else if initType == Modelica.Blocks.Types.InitPID.InitialState
                  or initType == Modelica.Blocks.Types.InitPID.DoNotUse_InitialIntegratorState
             then Modelica.Blocks.Types.Init.InitialState
             else Modelica.Blocks.Types.Init.NoInit) if
       with_I "Integral term"
       annotation (Placement(transformation(extent={{-40,-60},{-20,-40}})));

  Modelica.Blocks.Continuous.Derivative D(
    final k=Td/unitTime,
    final T=max([Td/Nd,1.e-14]),
    final x_start=xd_start,
    final initType=if initType == Modelica.Blocks.Types.InitPID.SteadyState or
                initType == Modelica.Blocks.Types.InitPID.InitialOutput
             then
               Modelica.Blocks.Types.Init.SteadyState
             else
               if initType == Modelica.Blocks.Types.InitPID.InitialState then
                 Modelica.Blocks.Types.Init.InitialState
               else
                 Modelica.Blocks.Types.Init.NoInit) if with_D "Derivative term"
                                                     annotation (Placement(
        transformation(extent={{-40,-10},{-20,10}})));

  Modelica.Blocks.Math.Add3 addPID(
    final k1=1,
    final k2=1,
    final k3=1) "Adder for the gains"
    annotation (Placement(transformation(extent={{0,-10},{20,10}})));

protected
  constant Modelica.SIunits.Time unitTime=1 annotation (HideResult=true);

  final parameter Real revAct = if reverseAction then -1 else 1
    "Switch for sign for reverse action";

  parameter Boolean with_I = controllerType==Modelica.Blocks.Types.SimpleController.PI or
                             controllerType==Modelica.Blocks.Types.SimpleController.PID
    "Boolean flag to enable integral action"
    annotation(Evaluate=true, HideResult=true);
  parameter Boolean with_D = controllerType==Modelica.Blocks.Types.SimpleController.PD or
                             controllerType==Modelica.Blocks.Types.SimpleController.PID
    "Boolean flag to enable derivative action"
    annotation(Evaluate=true, HideResult=true);

  Modelica.Blocks.Sources.Constant Dzero(final k=0) if not with_D
    "Zero input signal"
    annotation(Evaluate=true, HideResult=true,
               Placement(transformation(extent={{-30,20},{-20,30}})));

  Modelica.Blocks.Sources.Constant Izero(final k=0) if not with_I
    "Zero input signal"
    annotation(Evaluate=true, HideResult=true,
               Placement(transformation(extent={{10,-55},{0,-45}})));

  Modelica.Blocks.Interfaces.RealInput y_reset_internal
   "Internal connector for controller output reset"
   annotation(Evaluate=true);

  Modelica.Blocks.Math.Add3 addI(
    final k1=revAct,
    final k2=-revAct) if with_I
    "Adder for I gain"
       annotation (Placement(transformation(extent={{-80,-60},{-60,-40}})));

  Modelica.Blocks.Math.Add addSat(
    final k1=+1,
    final k2=-1) if with_I
    "Adder for integrator feedback"
    annotation (Placement(
        transformation(
        origin={80,-50},
        extent={{-10,-10},{10,10}},
        rotation=270)));

  Modelica.Blocks.Math.Gain gainPID(final k=k) "Multiplier for control gain"
   annotation (Placement(transformation(
          extent={{30,-10},{50,10}})));

  Modelica.Blocks.Math.Gain gainTrack(k=1/(k*Ni)) if with_I
    "Gain for anti-windup compensation"
    annotation (
      Placement(transformation(extent={{60,-80},{40,-60}})));

  Limiter limiter(
    final uMax=yMax,
    final uMin=yMin,
    final strict=strict)
    "Output limiter"
    annotation (Placement(transformation(extent={{70,-10},{90,10}})));


  Modelica.Blocks.Sources.RealExpression intRes(
    final y=y_reset_internal/k - addPID.u1 - addPID.u2) if
       reset <> BuildingSystems.Types.Reset.Disabled
    "Signal source for integrator reset"
    annotation (Placement(transformation(extent={{-80,-90},{-60,-70}})));

  // The block Limiter below has been implemented as it is introduced in MSL 3.2.3, but
  // not all tools include MSL 3.2.3.
  // See https://github.com/ibpsa/modelica-ibpsa/pull/1222#issuecomment-554114617
block Limiter "Limit the range of a signal"
  parameter Real uMax(start=1) "Upper limits of input signals";
  parameter Real uMin= -uMax "Lower limits of input signals";
  parameter Boolean strict=false "= true, if strict limits with noEvent(..)"
    annotation (Evaluate=true, choices(checkBox=true), Dialog(tab="Advanced"));
  parameter Boolean limitsAtInit=true
    "Has no longer an effect and is only kept for backwards compatibility (the implementation uses now the homotopy operator)"
    annotation (Dialog(tab="Dummy"),Evaluate=true, choices(checkBox=true));
  extends Modelica.Blocks.Interfaces.SISO;

equation
  assert(uMax >= uMin, "Limiter: Limits must be consistent. However, uMax (=" + String(uMax) +
                       ") < uMin (=" + String(uMin) + ")");

  if strict then
    y = smooth(0, noEvent(if u > uMax then uMax else if u < uMin then uMin else u));
  else
    y = smooth(0,if u > uMax then uMax else if u < uMin then uMin else u);
  end if;
  annotation (
     Icon(coordinateSystem(
    preserveAspectRatio=true,
    extent={{-100,-100},{100,100}}), graphics={
    Line(points={{0,-90},{0,68}}, color={192,192,192}),
    Polygon(
      points={{0,90},{-8,68},{8,68},{0,90}},
      lineColor={192,192,192},
      fillColor={192,192,192},
      fillPattern=FillPattern.Solid),
    Line(points={{-90,0},{68,0}}, color={192,192,192}),
    Polygon(
      points={{90,0},{68,-8},{68,8},{90,0}},
      lineColor={192,192,192},
      fillColor={192,192,192},
      fillPattern=FillPattern.Solid),
    Line(points={{-80,-70},{-50,-70},{50,70},{80,70}}),
    Text(
      extent={{-150,-150},{150,-110}},
      textString="uMax=%uMax"),
    Line(
      visible=strict,
      points={{50,70},{80,70}},
      color={255,0,0}),
    Line(
      visible=strict,
      points={{-80,-70},{-50,-70}},
      color={255,0,0})}),
    Diagram(coordinateSystem(
    preserveAspectRatio=true,
    extent={{-100,-100},{100,100}}), graphics={
    Line(points={{0,-60},{0,50}}, color={192,192,192}),
    Polygon(
      points={{0,60},{-5,50},{5,50},{0,60}},
      lineColor={192,192,192},
      fillColor={192,192,192},
      fillPattern=FillPattern.Solid),
    Line(points={{-60,0},{50,0}}, color={192,192,192}),
    Polygon(
      points={{60,0},{50,-5},{50,5},{60,0}},
      lineColor={192,192,192},
      fillColor={192,192,192},
      fillPattern=FillPattern.Solid),
    Line(points={{-50,-40},{-30,-40},{30,40},{50,40}}),
    Text(
      extent={{46,-6},{68,-18}},
      lineColor={128,128,128},
      textString="u"),
    Text(
      extent={{-30,70},{-5,50}},
      lineColor={128,128,128},
      textString="y"),
    Text(
      extent={{-58,-54},{-28,-42}},
      lineColor={128,128,128},
      textString="uMin"),
    Text(
      extent={{26,40},{66,56}},
      lineColor={128,128,128},
      textString="uMax")}));
end Limiter;


initial equation
  if initType==Modelica.Blocks.Types.InitPID.InitialOutput then
     gainPID.y = y_start;
  end if;

equation
  assert(yMax >= yMin, "LimPID: Limits must be consistent. However, yMax (=" + String(yMax) +
                       ") < yMin (=" + String(yMin) + ")");
  if initType == Modelica.Blocks.Types.InitPID.InitialOutput and (y_start < yMin or y_start > yMax) then
      Modelica.Utilities.Streams.error("LimPID: Start value y_start (=" + String(y_start) +
         ") is outside of the limits of yMin (=" + String(yMin) +") and yMax (=" + String(yMax) + ")");
  end if;

  // Equations for conditional connectors
  connect(y_reset_in, y_reset_internal);

  if reset <> BuildingSystems.Types.Reset.Input then
    y_reset_internal = y_reset;
  end if;

  connect(u_s, addP.u1) annotation (Line(points={{-120,0},{-96,0},{-96,56},{
          -82,56}}, color={0,0,127}));
  connect(u_s, addD.u1) annotation (Line(points={{-120,0},{-96,0},{-96,6},{
          -82,6}}, color={0,0,127}));
  connect(u_s, addI.u1) annotation (Line(points={{-120,0},{-96,0},{-96,-42},{
          -82,-42}}, color={0,0,127}));
  connect(addP.y, P.u) annotation (Line(points={{-59,50},{-42,50}}, color={0,
          0,127}));
  connect(addD.y, D.u)
    annotation (Line(points={{-59,0},{-42,0}}, color={0,0,127}));
  connect(addI.y, I.u) annotation (Line(points={{-59,-50},{-42,-50}}, color={
          0,0,127}));
  connect(P.y, addPID.u1) annotation (Line(points={{-19,50},{-10,50},{-10,8},
          {-2,8}}, color={0,0,127}));
  connect(D.y, addPID.u2)
    annotation (Line(points={{-19,0},{-2,0}}, color={0,0,127}));
  connect(I.y, addPID.u3) annotation (Line(points={{-19,-50},{-10,-50},{-10,
          -8},{-2,-8}}, color={0,0,127}));
  connect(addPID.y, gainPID.u)
    annotation (Line(points={{21,0},{28,0}}, color={0,0,127}));
  connect(gainPID.y, addSat.u2) annotation (Line(points={{51,0},{60,0},{60,
          -20},{74,-20},{74,-38}}, color={0,0,127}));
  connect(gainPID.y, limiter.u)
    annotation (Line(points={{51,0},{68,0}}, color={0,0,127}));
  connect(limiter.y, addSat.u1) annotation (Line(points={{91,0},{94,0},{94,
          -20},{86,-20},{86,-38}}, color={0,0,127}));
  connect(limiter.y, y)
    annotation (Line(points={{91,0},{110,0}}, color={0,0,127}));
  connect(addSat.y, gainTrack.u) annotation (Line(points={{80,-61},{80,-70},{62,
          -70}},    color={0,0,127}));
  connect(gainTrack.y, addI.u3) annotation (Line(points={{39,-70},{-88,-70},{-88,
          -58},{-82,-58}},     color={0,0,127}));
  connect(u_m, addP.u2) annotation (Line(
      points={{0,-120},{0,-92},{-92,-92},{-92,44},{-82,44}},
      color={0,0,127},
      thickness=0.5));
  connect(u_m, addD.u2) annotation (Line(
      points={{0,-120},{0,-92},{-92,-92},{-92,-6},{-82,-6}},
      color={0,0,127},
      thickness=0.5));
  connect(u_m, addI.u2) annotation (Line(
      points={{0,-120},{0,-92},{-92,-92},{-92,-50},{-82,-50}},
      color={0,0,127},
      thickness=0.5));
  connect(Dzero.y, addPID.u2) annotation (Line(points={{-19.5,25},{-14,25},{
          -14,0},{-2,0}}, color={0,0,127}));
  connect(Izero.y, addPID.u3) annotation (Line(points={{-0.5,-50},{-10,-50},{
          -10,-8},{-2,-8}}, color={0,0,127}));
  connect(trigger, I.trigger) annotation (Line(points={{-80,-120},{-80,-88},{-30,
          -88},{-30,-62}}, color={255,0,255}));
  connect(intRes.y, I.y_reset_in) annotation (Line(points={{-59,-80},{-50,-80},{
          -50,-58},{-42,-58}}, color={0,0,127}));
   annotation (
defaultComponentName="conPID",
Documentation(info="<html>
<p>
This model is similar to
<a href=\"modelica://Modelica.Blocks.Continuous.LimPID\">Modelica.Blocks.Continuous.LimPID</a>,
except for the following changes:
</p>

<ol>
<li>
<p>
It can be configured to have a reverse action.
</p>
<p>If the parameter <code>reverseAction=false</code> (the default), then
<code>u_m &lt; u_s</code> increases the controller output,
otherwise the controller output is decreased. Thus,
</p>
<ul>
  <li>for a heating coil with a two-way valve, set <code>reverseAction = false</code>, </li>
  <li>for a cooling coils with a two-way valve, set <code>reverseAction = true</code>. </li>
</ul>
</li>

<li>
<p>
It can be configured to enable an input port that allows resetting the controller
output. The controller output can be reset as follows:
</p>
<ul>
  <li>
  If <code>reset = BuildingSystems.Types.Reset.Disabled</code>, which is the default,
  then the controller output is never reset.
  </li>
  <li>
  If <code>reset = BuildingSystems.Types.Reset.Parameter</code>, then a boolean
  input signal <code>trigger</code> is enabled. Whenever the value of
  this input changes from <code>false</code> to <code>true</code>,
  the controller output is reset by setting <code>y</code>
  to the value of the parameter <code>y_reset</code>.
  </li>
  <li>
  If <code>reset = BuildingSystems.Types.Reset.Input</code>, then a boolean
  input signal <code>trigger</code> is enabled. Whenever the value of
  this input changes from <code>false</code> to <code>true</code>,
  the controller output is reset by setting <code>y</code>
  to the value of the input signal <code>y_reset_in</code>.
  </li>
</ul>
<p>
Note that this controller implements an integrator anti-windup. Therefore,
for most applications, keeping the default setting of
<code>reset = BuildingSystems.Types.Reset.Disabled</code> is sufficient.
Examples where it may be beneficial to reset the controller output are situations
where the equipment control input should continuously increase as the equipment is
switched on, such as as a light dimmer that may slowly increase the luminance, or
a variable speed drive of a motor that should continuously increase the speed.
</p>
</li>

<li>
The parameter <code>limitsAtInit</code> has been removed.
</li>

<li>
Some parameters assignments in the instances have been made final.
</li>

</ol>
</html>",
revisions="<html>
<ul>
<li>
March 9, 2020, by Michael Wetter:<br/>
Corrected wrong unit declaration for parameter <code>k</code>.<br/>
This is for <a href=\"https://github.com/ibpsa/modelica-ibpsa/issues/1316\">issue 1316</a>.
<li>
October 19, 2019, by Filip Jorissen:<br/>
Disabled homotopy to ensure bounded outputs
by copying the implementation from MSL 3.2.3 and by
hardcoding the implementation for <code>homotopyType=NoHomotopy</code>.
See <a href=\"https://github.com/ibpsa/modelica-ibpsa/issues/1221\">issue 1221</a>.
</li>
<li>
September 29, 2016, by Michael Wetter:<br/>
Refactored model.
</li>
<li>
August 25, 2016, by Michael Wetter:<br/>
Removed parameter <code>limitsAtInit</code> because it was only propagated to
the instance <code>limiter</code>, but this block no longer makes use of this parameter.
This is a non-backward compatible change.<br/>
Revised implemenentation, added comments, made some parameter in the instances final.
</li>
<li>July 18, 2016, by Philipp Mehrfeld:<br/>
Added integrator reset.
This is for <a href=\"https://github.com/ibpsa/modelica-ibpsa/issues/494\">issue 494</a>.
</li>
<li>
March 15, 2016, by Michael Wetter:<br/>
Changed the default value to <code>strict=true</code> in order to avoid events
when the controller saturates.
This is for <a href=\"https://github.com/ibpsa/modelica-ibpsa/issues/433\">issue 433</a>.
</li>
<li>
February 24, 2010, by Michael Wetter:<br/>
First implementation.
</li>
</ul>
</html>"), Icon(graphics={
        Rectangle(
          extent={{-6,-20},{66,-66}},
          lineColor={255,255,255},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Text(
          visible=(controllerType == Modelica.Blocks.Types.SimpleController.P),
          extent={{-32,-22},{68,-62}},
          lineColor={0,0,0},
          textString="P",
          fillPattern=FillPattern.Solid,
          fillColor={175,175,175}),
        Text(
          visible=(controllerType == Modelica.Blocks.Types.SimpleController.PI),
          extent={{-28,-22},{72,-62}},
          lineColor={0,0,0},
          textString="PI",
          fillPattern=FillPattern.Solid,
          fillColor={175,175,175}),
        Text(
          visible=(controllerType == Modelica.Blocks.Types.SimpleController.PD),
          extent={{-16,-22},{88,-62}},
          lineColor={0,0,0},
          fillPattern=FillPattern.Solid,
          fillColor={175,175,175},
          textString="P D"),
        Text(
          visible=(controllerType == Modelica.Blocks.Types.SimpleController.PID),
          extent={{-14,-22},{86,-62}},
          lineColor={0,0,0},
          textString="PID",
          fillPattern=FillPattern.Solid,
          fillColor={175,175,175}),
        Polygon(
          points={{-80,90},{-88,68},{-72,68},{-80,90}},
          lineColor={192,192,192},
          fillColor={192,192,192},
          fillPattern=FillPattern.Solid),
        Line(points={{-80,78},{-80,-90}}, color={192,192,192}),
        Line(points={{-80,-80},{-80,-20},{30,60},{80,60}}, color={0,0,127}),
        Line(points={{-90,-80},{82,-80}}, color={192,192,192}),
        Polygon(
          points={{90,-80},{68,-72},{68,-88},{90,-80}},
          lineColor={192,192,192},
          fillColor={192,192,192},
          fillPattern=FillPattern.Solid),
        Line(
          visible=strict,
          points={{30,60},{81,60}},
          color={255,0,0},
          smooth=Smooth.None)}));
end LimPID;
