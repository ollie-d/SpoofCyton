program SendCytonData;

uses
  Vcl.Forms,
  StreamCytonData in 'StreamCytonData.pas' {Form2},
  Unit2 in 'Unit2.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
