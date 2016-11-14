program TBTG;

uses
  System.StartUpCopy,
  FMX.Forms,
  classTile in 'classTile.pas',
  classUnit in 'classUnit.pas',
  classWorld in 'classWorld.pas',
  GameValues in 'GameValues.pas',
  Main in 'Main.pas' {MainForm},
  classActValues in 'classActValues.pas',
  Tutorial in 'Tutorial.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
