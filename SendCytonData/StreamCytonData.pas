unit StreamCytonData;
//http://delphiprogrammingdiary.blogspot.com/2018/02/delphi-ioutils-accessing-and-changing.html
//https://stackoverflow.com/questions/988733/how-to-delete-files-matching-pattern-within-a-directory

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.FileCtrl,
  System.IOUtils, Math, IdTCPClient, IdBaseComponent, IdComponent, IdTCPConnection;

type
  TForm2 = class(TForm)
    ProgressBar1: TProgressBar;
    ProgressBar2: TProgressBar;
    btnStart: TButton;
    Memo1: TMemo;
    Memo2: TMemo;
    btnSelectFolder: TButton;
    mmDataFiles: TMemo;
    Times1: TMemo;
    btnServer: TButton;
    procedure btnStartClick(Sender: TObject);
    procedure btnSelectFolderClick(Sender: TObject);
    procedure btnServerClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

type
  StreamThread = class(TThread)
  protected
    procedure Execute; override;
    procedure SetMemo(mm: TMemo; bar: TProgressBar; index: Integer);
    procedure DoProgress;
  private
    Start, Stop, Frequency: Int64;
    Elapsed: Single;
    prog: Integer;
  end;

type
  MemoThread = class(TThread)
  protected
    procedure Execute; override;
    procedure SetMemo(memo_: TMemo; bar_: TProgressBar);
    procedure SetFileName(fileName_: String);
  private
    fileName: String;
    memo: TMemo;
    bar: TProgressBar;
    test, prog: Integer;
  end;


var
  fs, dt: Single;
  Form2: TForm2;
  ActiveBar:    TProgressBar;
  ActiveMemo: TMemo;
  ActiveIndex: Integer;
  NumFiles: Integer;
  Dir: String; // Where files are located
  interval: Integer = 500; // every 500 lines updates progress bar
  should_terminate: Boolean = False;
  Client: TIdTCPClient;

implementation

{$R *.dfm}

{ StreamThread }
procedure StreamThread.DoProgress;
begin
  ActiveBar.Position := prog;
  //ActiveBar.Refresh;
end;

procedure StreamThread.SetMemo(mm: TMemo; bar: TProgressBar; index: Integer);
begin
  ActiveMemo := mm;
  ActiveBar := bar;
  ActiveBar.Max := ActiveMemo.Lines.Count;
  ActiveIndex := index;
end;

procedure StreamThread.Execute;
var
  i, j, interval: Integer;
  InitStart: Int64;
  child: MemoThread;
begin
  FreeOnTerminate := True;

  // Create master timer
  QueryPerformanceFrequency(Frequency);

  // Initiate to state 1, fill state 2 via child
  SetMemo(Form2.Memo1, Form2.ProgressBar1, 1);
  child := MemoThread.Create(True);
  child.SetMemo(Form2.Memo2, Form2.ProgressBar2);
  child.SetFileName(Form2.mmDataFiles.Lines[1]); // 2nd file
  child.Execute;

  QueryPerformanceCounter(InitStart);
  interval := 500;

  for j := 1 to numFiles do
  begin
    // Skip first file (weird edge case)
    if j > 1 then
    begin
      // Switch focus and populate the other memo
      if ActiveIndex = 1 then
      begin
        SetMemo(Form2.Memo2, Form2.ProgressBar2, 2);
        child := MemoThread.Create(True);
        child.SetMemo(Form2.Memo1, Form2.ProgressBar1);
      end
      else
      begin
        SetMemo(Form2.Memo1, Form2.ProgressBar1, 1);
        child := MemoThread.Create(True);
        child.SetMemo(Form2.Memo2, Form2.ProgressBar2);
      end;

      // Set child fileName to next file, then execute
      child.SetFileName(Form2.mmDataFiles.Lines[j]);
      child.Execute;
    end;

    for i := 0 to ActiveMemo.Lines.Count do
    begin
      // Determine if we should terminate
      if should_terminate then
        exit;

      // Send Data to Moment Here
      Client.IOHandler.WriteLn(ActiveMemo.Lines[i]);

      // Update progress bar when needed
      prog := ActiveBar.Max - i;
      if i mod interval = 0 then Queue(DoProgress);

      // Wait dt (in our case 4ms)
      QueryPerformanceCounter(Start);
      QueryPerformanceCounter(Stop);
      Elapsed := 0.0;
      while Elapsed < dt do
      begin
        QueryPerformanceCounter(Stop);
        Elapsed := (Stop - Start) / Frequency;
      end;
      Application.ProcessMessages; // Allows for stopping
    end;
  end;

  // Debug

  QueryPerformanceCounter(Stop);
  ShowMessage('Expected Time (seconds): ' + FloatToStr(ActiveMemo.Lines.Count * 0.004));
  ShowMessage('Actual Time (seconds): ' + FloatToStr((Stop - InitStart) / Frequency));

end;

{ MemoThread }
procedure MemoThread.SetMemo(memo_: TMemo; bar_: TProgressBar);
begin
  memo := memo_;
  bar := bar_;
end;

procedure MemoThread.SetFileName(FileName_: String);
begin
  fileName := FileName_;
end;

procedure MemoThread.Execute;
begin
  // Do we freeonterminate or no?
  // Not sure if it's cheaper to keep the thread alive or 
  // If it's safer to let it die and spawn a new one
  // Read file directly to memo
  FreeOnTerminate := True;
  memo.Clear;
  memo.Lines.LoadFromFile(fileName);
  bar.Max := memo.Lines.Count;
  bar.Position := bar.Max;
  bar.Refresh;
  Application.ProcessMessages;
end;

{ Form2 }
function ListDataFiles(dir_: String; saveTo: TMemo): Integer;
var
  FileName: string;
begin
  Result := 0;
  saveTo.Clear;
  for FileName in TDirectory.GetFiles(dir_, '*_trl.txt') do
  begin
    saveTo.Lines.Add(FileName);
    Result := Result + 1;
  end;
end;

procedure ProcessFirstFile(FileName: String);
// NOTE: Currently assumes files are sorted temporally automatically
// NOTE: Will automatically save to Memo1
var
  File_: TStringList;
  line: String;
  counter: Integer;
begin
  File_ := TStringList.Create;
  File_.LoadFromFile(FileName);
  for counter := 0 to File_.Count-1 do
  begin
    line := File_.Strings[counter];
    if line[1] = '1' then
      break;
  end;

  // Add lines to Memo1 (update bar1 too)
  Form2.ProgressBar1.Max := File_.Count;
  for counter := counter to File_.Count-1 do
  begin
    Form2.Memo1.Lines.Add(File_.Strings[counter]);
    Form2.ProgressBar1.Position := counter;
  end;
end;

procedure TForm2.btnSelectFolderClick(Sender: TObject);
begin
  btnStart.Enabled := True;
  with TFileOpenDialog.Create(nil) do
  try
    Options := [fdoPickFolders];
    if Execute then
      Dir := FileName;
  finally
    Free;
  end;

  // List all data files and count number
  NumFiles := ListDataFiles(Dir, mmDataFiles);

  // Process first file
  ProcessFirstFile(mmDataFiles.Lines[0]);
end;

procedure TForm2.btnServerClick(Sender: TObject);
begin
  // Connect to moment server; code adapted from moment_client

  // Create client
  Client := TIdTCPClient.Create(Application);

  // Connect to localhost
  Client.Host := '127.0.0.1';
  Client.port := 1024;
  Client.Connect;//Activates the client socket

  Sleep(200);
  if Client.Connected then
    btnSelectFolder.Enabled := True;
end;

procedure TForm2.btnStartClick(Sender: TObject);
var
  Thread: StreamThread;
begin
  if btnStart.Caption = 'Stop' then
  begin
    should_terminate := True;
    btnStart.Caption := 'Start';
    btnSelectFolder.Enabled := True;
    btnStart.Refresh;
    ShowMessage('We outta here');
    // Add code to stop things from happening
    exit;
  end
  else
  begin
    btnStart.Caption := 'Stop';
    btnStart.Refresh;
    btnSelectFolder.Enabled := False;
  end;
  
  // Set fs to Cyton default and calculate dt
  fs := 250.0; // Cyton default
  dt := 1.0 / fs; // 0.004s (4ms)

  // Create thread (suspended)
  Thread := StreamThread.Create(True);
  Thread.Priority := tpTimeCritical;

  // Start our thread
  Thread.Execute;
end;

end.
