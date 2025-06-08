
program MyProgram;

uses cthreads, CubeDefs, CubiCube, CordCube, Symmetries, Search, Unix, SysUtils;

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

var cc: CubieCube;
    cc2: CoordCube;
    idaObj: IDA;
    scramble: String;
    solLen: Integer;
    tv1: TTimeVal;
    tv2: TTimeVal;
begin
  USES_BIG := (paramCount() > 0) and (paramStr(1) = '-b');

  CreateSymmetryTables;
  CreateGetPackedTable;

  CreateClassIndexToRepresentantTables;
  CreateMoveTables;
  CreateConjugateTables;
  CreatePruningTables;

  CreateGetPruningLengthTable;
  CreateGetEdge8PermTable;

  while not EOF do
  begin
    ReadLn(scramble);
    cc := parseScramble(scramble);
    cc2 := CoordCube.Create(cc);
    idaObj := IDA.Create(cc2);
    idaObj.maxLength := 30;
    idaObj.runOptimal := true;
    fpGetTimeOfDay(@tv1, nil);
    solLen := idaObj.NextSolution(30);
    fpGetTimeOfDay(@tv2, nil);
    writeln('Solved in ', solLen, ' moves, nodes= ', idaObj.NodeCount,
      ' tt= ', (tv2.tv_sec - tv1.tv_sec) + (tv2.tv_usec - tv1.tv_usec)/1e6:0:3, ' s',
      ' sol= ', idaObj.solverString);
  end;
end.