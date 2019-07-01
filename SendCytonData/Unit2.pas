unit Unit2;

interface

uses
  System.Classes, Vcl.StdCtrls;

type
  TMyThread = class(TThread)
  private
    { Private declarations }
  protected
    constructor Create(CreateSuspended: Boolean);
    procedure Execute; override;
    procedure SetMemo(memo: TMemo);
  end;

implementation

{ 
  Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);  

  and UpdateCaption could look like,

    procedure TMyThread.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; 
    
    or 
    
    Synchronize( 
      procedure 
      begin
        Form1.Caption := 'Updated in thread via an anonymous method' 
      end
      )
    );
    
  where an anonymous method is passed.
  
  Similarly, the developer can call the Queue method with similar parameters as 
  above, instead passing another TThread class as the first parameter, putting
  the calling thread in a queue with the other thread.
    
}

{ TMyThread }

constructor TMyThread.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  Priority := tpTimeCritical; // Maximum Priority
  FreeOnTerminate := True;
end;

procedure TMyThread.SetMemo(memo: TMemo);
begin
  // Hey
end;

procedure TMyThread.Execute;
begin
  { Place thread code here }
  // Main Thread

end;

end.
