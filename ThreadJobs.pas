unit ThreadJobs;

interface
uses Classes,SyncObjs,Generics.Collections;

type
  TThreadJob=class
    Job : TThreadProcedure;
    constructor Create(J : TThreadProcedure);
  end;

  TJobThread = class;
  TJobThreadList = TObjectList<TJobThread>;

  TThreadJobQueue = class(TObjectQueue<TThreadJob>)
    WakeUp,AllPause : TEvent;
    Lock : TMutex;
    ThreadList : TJobThreadList;
    RunningThread : integer;
    clearing : boolean;
    needpause : boolean;
    pauseLock : TMutex;
    procedure Run(J : TThreadProcedure);
    constructor Create(ThreadCount : integer);
    destructor Destroy; override;
    procedure ClearJobs;
    procedure PauseAll;
    procedure ResumeAll;
  end;

  TJobThread = class(TThread)
    JQ : TThreadJobQueue;
    procedure Execute; override;
    constructor Create(Q : TThreadJobQueue);
  end;

implementation
uses SysUtils;

{ TThreadJobQueue }

procedure TThreadJobQueue.ClearJobs;
begin
  clearing := true;
  Lock.Acquire;
  Clear;
  Lock.Release;
  AllPause.WaitFor;
  clearing := false;
end;

constructor TThreadJobQueue.Create(ThreadCount : integer);
var i : integer;
begin
  inherited Create;
  clearing := false;
  AllPause := TEvent.Create;
  WakeUp := TEvent.Create;
  Lock := TMutex.Create;
  ThreadList := TJobThreadList.Create;
  for i := 1 to ThreadCount do begin
    ThreadList.Add(TJobThread.Create(self));
  end;
end;

destructor TThreadJobQueue.Destroy;
var J : TJobThread;
begin
  for J in ThreadList do
  begin
    J.Terminate;
  end;
  Lock.Acquire;
  WakeUp.SetEvent;
  Lock.Release;
  for J in ThreadList do
  begin
    J.WaitFor;
  end;
  ThreadList.Free;
  WakeUp.Free;
  Lock.Free;
  AllPause.Free;
  inherited;
end;

procedure TThreadJobQueue.PauseAll;
begin
  PauseLock.Acquire;
  NeedPause := true;
  AllPause.WaitFor;
  PauseLock.Release;
end;

procedure TThreadJobQueue.ResumeAll;
begin
  PauseLock.Acquire;
  NeedPause := false;
  PauseLock.Release;
  WakeUp.SetEvent;
end;

procedure TThreadJobQueue.Run(J: TThreadProcedure);
begin
  if clearing then exit;
  Lock.Acquire;
  if not clearing then begin
    Enqueue(TThreadJob.Create(J));
    if Count=1 then WakeUp.SetEvent;
  end;
  Lock.Release;
end;

{ TJobThread }

constructor TJobThread.Create(Q: TThreadJobQueue);
begin
  JQ := Q;
  inherited Create;
end;

procedure TJobThread.Execute;
var J : TThreadJob;
begin
  if TInterlocked.Increment(JQ.RunningThread)=1 then JQ.AllPause.ResetEvent;
  try
    while not Terminated do begin
      J :=nil;
      if not JQ.needpause then begin
        JQ.Lock.Acquire;
        try
          if not(Terminated or JQ.needpause) then
            if JQ.Count=0 then JQ.WakeUp.ResetEvent
            else J := JQ.Extract;
        finally
          JQ.Lock.Release;
        end;
      end;
      if assigned(J) then begin
        try
          J.Job();
        except on E: Exception do
        end;
        J.Free;
      end else if not Terminated then begin
        if TInterLocked.Decrement(JQ.RunningThread)=0 then JQ.AllPause.SetEvent;
        JQ.WakeUp.WaitFor;
        if TInterlocked.Increment(JQ.RunningThread)=1 then JQ.AllPause.ResetEvent;
      end;
    end;
  finally
    if TInterLocked.Decrement(JQ.RunningThread)=0 then JQ.AllPause.SetEvent;
  end;
end;

{ TThreadJob }

constructor TThreadJob.Create(J: TThreadProcedure);
begin
  Job := J;
end;

end.
