program MyProgram;

uses cthreads, CubeDefs, CubiCube, CordCube, Symmetries, Search, Unix, SysUtils, SyncObjs, Classes;

type TSearcher = class(IDA)
public
    constructor Create(CoordCube: CoordCube); overload;
    procedure Execute; override;
end;

constructor TSearcher.Create(CoordCube: CoordCube);
begin
    inherited Create(CoordCube);
end;

var scrambles: TStrings;
    scramble: String;
    nSolving, scrIdx, i1: Integer;
    Lock: TCriticalSection;
    eofEvent: TEventObject;

function parseScramble(scramble: String): CubieCube;
var cc: CubieCube;
  i,j,n,pow,pp: Integer;
  t,t1:TurnAxis;
begin
  cc := CubieCube.Create;
  scramble:= scramble + ' ';
  n:=Length(scramble);
  t:=U;
  pp:=0;
  for i:= 1 to n do
  begin
    case scramble[i] of
      'U': t:=U;
      'R': t:=R;
      'F': t:=F;
      'D': t:=D;
      'L': t:=L;
      'B': t:=B;
      'E': t:=E;
      'M': t:=M;
      'S': t:=S;
      'x': t:=Us;
      'y': t:=RS;
      'z': t:=Fs;
    else
      continue;
    end;

    case scramble[i+1] of
      '3','''': pow:=3;
      '2': pow:=2;
      's': begin pow:=4;pp:=1; end;//nicht sehr eleganter Patch
      'a': begin pow:=4;pp:=2; end;
    else
      pow:=1;
    end;
    if (pow<4)then
    begin for j:= 1 to pow do cc.Move(t); end
    else //Xs oder Xa
    begin
      if t<=F then t1:= TurnAxis(Ord(t)+3) else t1:= TurnAxis(Ord(t)-3);
      case scramble[i+2] of //mit Sicherheit noch nicht Stringende erreicht
         '3','''': pow:=3;   //!!!!!!!!!!!!!!!!!!!!!erg�nzt
         '2': pow:=2;
      else
        pow:=1;
      end;
      if pp=1 then//Slice move
      begin
        for j:= 1 to pow do cc.Move(t);
        for j:= 1 to 4-pow do  cc.Move(t1);
      end
      else //antislice move
      begin
        for j:= 1 to pow do cc.Move(t);
        for j:= 1 to pow do cc.Move(t1);
      end;
    end;
  end;
  Result := cc;
end;

procedure doNextScramble(Sender: TObject);
var cc: CubieCube;
    cc2: CoordCube;
    scramble: String;
    nextIda: TSearcher;
begin
    Dec(nSolving);
    if scrIdx < scrambles.Count then begin
        scramble := scrambles[scrIdx];
        Inc(scrIdx);
        Inc(nSolving);
        cc := parseScramble(scramble);
        cc2 := CoordCube.Create(cc);
        nextIda := TSearcher.Create(cc2);
        nextIda.maxLength := 30;
        nextIda.runOptimal := true;
        nextIda.FreeOnTerminate := true;
        nextIda.start();
    end else if nSolving = 0 then begin
        eofEvent.SetEvent;
    end;
end;

procedure TSearcher.Execute;
var StartTime, EndTime: TTimeVal;
begin
    fpGetTimeOfDay(@StartTime, nil);
    inherited;
    fpGetTimeOfDay(@EndTime, nil);
    Lock.Acquire;
    writeln('Solved in ', returnLength, ' moves, nodes= ', NodeCount,
      ' tt= ', (EndTime.tv_sec - StartTime.tv_sec) + (EndTime.tv_usec - StartTime.tv_usec)/1e6:0:3, ' s',
      ' sol= ', solverString);
    doNextScramble(self);
    Lock.Release;
end;

begin
  nSolving := 1;
  for i1 := 1 to paramCount do begin
      if paramStr(i1) = '-b' then begin
      USES_BIG := true;
    end else if paramStr(i1) = '-t' then begin
      nSolving := StrToInt(paramStr(i1+1));
    end;
  end;

  CreateSymmetryTables;
  CreateGetPackedTable;

  CreateClassIndexToRepresentantTables;
  CreateMoveTables;
  CreateConjugateTables;
  CreatePruningTables;

  CreateGetPruningLengthTable;
  CreateGetEdge8PermTable;

  scrambles := TStringList.Create;
  while not EOF do begin
    readln(scramble);
    scrambles.Add(scramble);
  end;
  eofEvent := TEventObject.Create(nil, true, false, '');
  Lock := TCriticalSection.Create;
  scrIdx := 0;
  Lock.Acquire;
  for i1 := 1 to nSolving do doNextScramble(nil);
  Lock.Release;
  eofEvent.WaitFor(INFINITE);
end.
