unit BitGrid;

{$MODE Delphi}

interface
uses
  classes;


procedure Compute_A;                       // does all the computing for set A

procedure Compute_B;                       // does all the computing for set B

function GetHex(var s : string):integer;   // gets a hex string, killing any leading spaces

procedure SaveTo(filename : string);       // saves the program to a file

function  GetCycleCount : LongInt;         // how many cycles have we comptued so far?

procedure DumpStateTo(o : TStrings);       // dump the current cells, inputs, outputs to a list

procedure LoadCellsFrom(o : TStrings);     // reload the program from a list

procedure SaveCellsTo(o : TStrings);        // save program cells to a string list

implementation

uses
  sysutils;

type
  TBitGridCell = Class(TObject)
    Instruction : Array[0..3] of integer;   // 4 in, 4 out lut
    Index       : integer;
    Inputs      : Array[0..3] of ^Boolean;  // allow for non-uniform stuff later
    Outputs     : Array[0..3] of Boolean;
    Constructor Create;
    Procedure   Compute;                    // have it do its own computation
  End;

const
  xsize = 8;
  ysize = 8;
  alwaysfalse : boolean = false;    // default to this for inputs
  alwaystrue  : boolean = true;

var
  cycles : longint;
  cells : array[0..xsize-1,0..ysize-1] of TBitGridCell;

function describe(instruction : integer) : string;
var
  s : string;
begin
  s := IntToHex(instruction,4);
  case instruction of
    0      :  s := '#false';
    $ffff  :  s := '#true';
    $ff00  :  s := '#left';
    $f0f0  :  s := '#below';
    $cccc  :  s := '#right';
    $aaaa  :  s := '#above';
  end; // case Instruction
  describe := s;
end;


procedure compute_a;
var
  x,y : integer;
  index   : integer;
begin
  for x := 0 to xsize-1 do
    for y := 0 to ysize-1 do
      if ((x+y) mod 2) = 0 then   // only do  phase 1 cells
        cells[x,y].compute;
  inc(cycles);
end;

procedure compute_b;
var
  x,y : integer;
  index   : integer;
begin
  for x := 0 to xsize-1 do
    for y := 0 to ysize-1 do
      if ((x+y) mod 2) <> 0 then   // only do  phase 2 cells
      begin
        cells[x,y].compute;
      end;
end;


function GetHex(var s : string):integer;
var
  x : integer;
begin
  x := 0;
  while (length(s) > 0) AND (s[1] = ' ') do delete(s,1,1);   // strip off leading spaces
  while (length(s) > 0) AND (s[1] in ['0'..'9','A'..'F','a'..'f']) do
  begin
    case s[1] of
      '0'..'9' : x := (x * 16)      + (ord(s[1])-ord('0'));
      'A'..'F' : x := (x * 16) + 10 + (ord(s[1])-ord('A'));
      'a'..'f' : x := (x * 16) + 10 + (ord(s[1])-ord('a'));
    end;
    delete(s,1,1);
  end;
  gethex := x;
end;

procedure SaveTo(filename : string);
var
  f : text;
  s : string;
  x,y : integer;
begin
  assign(f,filename);
  rewrite(f);
  for y := 0 to ysize-1 do
  begin
    s := '';
    for x := 0 to xsize-1 do
    begin
      s := s + inttohex(cells[x,y].Instruction[0],4) + ' ';
      s := s + inttohex(cells[x,y].Instruction[1],4) + ' ';
      s := s + inttohex(cells[x,y].Instruction[2],4) + ' ';
      s := s + inttohex(cells[x,y].Instruction[3],4) + '    ';
    end;
    writeln(f,s);
  end; // for y
  close(f);
end;

function GetCycleCount : LongInt;
begin
  GetCycleCount := Cycles;
end;

procedure DumpStateTo(o : TStrings);
var
  x,y : integer;
  s   : string;
begin
  o.Clear;
  o.Append('Program State:');
  for y := 0 to ysize-1 do
  begin
    s := '';
    for x := 0 to xsize-1 do
    begin
      s := s + describe(cells[x,y].Instruction[0]) + ' ';
      s := s + describe(cells[x,y].Instruction[1]) + ' ';
      s := s + describe(cells[x,y].Instruction[2]) + ' ';
      s := s + describe(cells[x,y].Instruction[3]) + '     ';
    end;
    o.Append(s);
  end; // for y

  o.Append('Input State:');
  for y := 0 to ysize-1 do
  begin
    s := '';
    for x := 0 to xsize-1 do
      s := s + inttohex(cells[x,y].Index,4) + ' ';
    o.Append(s);
  end; // for y

  o.Append('Output State:');
  for y := 0 to ysize-1 do
  begin
    s := '';
    for x := 0 to xsize-1 do
    begin
      s := s + BoolToStr(cells[x,y].Outputs[0]) + ' ';
      s := s + BoolToStr(cells[x,y].Outputs[1]) + ' ';
      s := s + BoolToStr(cells[x,y].Outputs[2]) + ' ';
      s := s + BoolToStr(cells[x,y].Outputs[3]) + '     ';
    end;
    o.Append(s);
  end; // for y
end;

procedure LoadCellsFrom(o : TStrings);     // reload the program from a list
var
  x,y : integer;
  s   : string;
begin
  for y := 0 to ysize-1 do
  begin
    s := o.Strings[y];
    for x := 0 to xsize-1 do
    begin
      cells[x,y].Instruction[0] := gethex(s);
      cells[x,y].Instruction[1] := gethex(s);
      cells[x,y].Instruction[2] := gethex(s);
      cells[x,y].Instruction[3] := gethex(s);
    end;
  end; // for y
end;

procedure SaveCellsTo(o : TStrings);        // save program cells to a string list
var
  x,y : integer;
  s   : string;
begin
  o.Clear;
  for y := 0 to ysize-1 do
  begin
    s := '';
    for x := 0 to xsize-1 do
    begin
      s := s + ' ' + inttohex(cells[x,y].Instruction[0],4);
      s := s + ' ' + inttohex(cells[x,y].Instruction[1],4);
      s := s + ' ' + inttohex(cells[x,y].Instruction[2],4);
      s := s + ' ' + inttohex(cells[x,y].Instruction[3],4)+ '    ';
    end;
    o.Append(s);
  end; // for y
end;

Constructor TBitGridCell.Create;
begin
  Instruction[3] := $cccc;     // left output is copy of right input
  Instruction[2] := $aaaa;     // bottom output is copy of upper input
  Instruction[1] := $ff00;     // right output is copy of left input
  Instruction[0] := $f0f0;     // top output is copy of bottom input
  Index       := 0;
  Inputs[3] := @AlwaysFalse; // left- default to a false input, for safety.
  Inputs[2] := @AlwaysFalse; // below
  Inputs[1] := @AlwaysFalse; // right
  Inputs[0] := @AlwaysFalse; // above
end;

Procedure   TBitGridCell.Compute;
begin
  index := 1;
  if inputs[3]^ then index := index shl 8;
  if inputs[2]^ then index := index shl 4;
  if inputs[1]^ then index := index shl 2;
  if inputs[0]^ then index := index shl 1;

  Outputs[3] := (index AND (instruction[3])) <> 0;
  Outputs[2] := (index AND (instruction[2])) <> 0;
  Outputs[1] := (index AND (instruction[1])) <> 0;
  Outputs[0] := (index AND (instruction[0])) <> 0;
end;



//  $ff00  --- anything from the left
//  $f0f0  --- anything from below
//  $cccc  --- anything from the right
//  $aaaa  --- anything from the above

var
  x,y : integer;
initialization
  cycles := 0;
  for x := 0 to xsize-1 do
    for y := 0 to ysize-1 do
      cells[x,y] := TBitGridCell.Create;   // set up the cell

  for x := 0 to xsize-1 do
    for y := 0 to ysize-1 do
    begin
      cells[x,y].Inputs[3] := @cells[(x+xsize-1) mod xsize,y].Outputs[1];   // hook up left side input
      cells[x,y].Inputs[1] := @cells[(x+1)       mod xsize,y].Outputs[3];   // hook up right side
      cells[x,y].Inputs[2] := @cells[x,(y+ysize-1) mod ysize].Outputs[0];   // hook up bottomm side
      cells[x,y].Inputs[0] := @cells[x,(y+1)       mod ysize].Outputs[2];   // hook up top side
    end; // for y

end.
