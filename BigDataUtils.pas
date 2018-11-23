unit BigDataUtils;

interface
type
  BigData=Record
  class var DefaultPrec : Cardinal;
  var
    Positive : integer;
    Power : integer;
    Precise : Cardinal;
    DATA : TArray<Cardinal>;
    class constructor InitBigData;
    constructor Create(Prec : Cardinal);
    procedure TrimData;
    function ToString: String; overload;
    class operator Implicit(a: Int64): BigData;
    class operator Explicit(a: BigData): int64;
    class operator Implicit(a: UInt64): BigData;
    class operator Explicit(a: BigData): Uint64;
    class operator Implicit(a: Double): BigData;
    class operator Explicit(a: BigData): Double;
    class operator Explicit(a: String): BigData;
  End;
//haha
implementation
uses Generics.Collections, System.SysUtils, Math;

resourcestring
  StrBigDataTooBig = 'BigData is too big for assigned';
  StrNegToUnSigned = 'Assigning a Negative Value to an Unsigned Variable';
  StrBadNumberFormat = 'Bad Number Format';

function Div64_9(var a :UInt64):Cardinal; inline;
{$IFNDEF CPU64BITS}
var d : Cardinal;
    c : Uint64;
{$ENDIF}
begin
{$IFDEF CPU64BITS}
  Result := a div 1000000000;
  a := a-Result*1000000000;
{$ELSE}
  Result := 0;
  c := 1000000000 shl 29;
  d := 1 shl 29;
  while a>=1000000000 do begin
    if a>=c then begin
      a := a-c;
      Result := Result+d;
    end;
    c := c shr 1;
    d := d shr 1;
  end;
{$ENDIF}
end;

function Div64_2(var a :UInt64):Cardinal; inline;
{$IFNDEF CPU64BITS}
var d : Cardinal;
    c : Uint64;
{$ENDIF}
begin
{$IFDEF CPU64BITS}
  Result := a div 1000000000000000000;
  a := a-Result*1000000000000000000;
{$ELSE}
  Result := 0;
  c := UInt64(1000000000000000000) shl 4;
  d := 1 shl 4;
  while a>=1000000000000000000 do begin
    if a>=c then begin
      a := a-c;
      Result := Result+d;
    end;
    c := c shr 1;
    d := d shr 1;
  end;
{$ENDIF}
end;

function Div64_1(var a :UInt64):Cardinal; inline;
{$IFNDEF CPU64BITS}
var d : Cardinal;
    c : Uint64;
{$ENDIF}
begin
{$IFDEF CPU64BITS}
  Result := a div 1000000000000000000;
  a := a-Result*1000000000000000000;
{$ELSE}
  Result := 0;
  c := 1000000000000000000 shl 3;
  d := 1 shl 3;
  while a>=1000000000000000000 do begin
    if a>=c then begin
      a := a-c;
      Result := Result+d;
    end;
    c := c shr 1;
    d := d shr 1;
  end;
{$ENDIF}
end;

{ BigData }

constructor BigData.Create(Prec: Cardinal);
begin
  Precise := Prec;
  Positive := 0;
  Data := nil;
end;

class operator BigData.Implicit(a: UInt64): BigData;
var b : UInt64;
    c : Cardinal;
begin
  if a=0 then begin
    Result.Positive := 0;
    exit;
  end;
  Result.Positive := 1;
  if a<1000000000 then begin
    SetLength(Result.DATA,1);
    Result.Power := 1;
    Result.DATA[0] := a;
  end else begin
    b := Div64_9(a);
    if a<1000000000 then begin
      SetLength(Result.DATA,2);
      Result.Power := 2;
      Result.DATA[0] := b;
      Result.DATA[1] := a;
    end else begin
      c := Div64_2(b);
      SetLength(Result.DATA,3);
      Result.Power := 3;
      Result.DATA[0] := c;
      Result.DATA[1] := b;
      Result.DATA[2] := a;
    end;
  end;
end;

class operator BigData.Explicit(a: String): BigData;
var c : char;
    e,ep,dp,i,j : integer;
begin
  a := a.Replace(',','');
  a := UpperCase(a);
  if a.Chars[0]='-' then begin
    Result.Positive := -1;
    a := a.Remove(0,1);
  end else begin
    Result.Positive := 1;
    if a.Chars[0]='+' then a := a.Remove(0,1);
  end;
  ep := a.IndexOf('E');
  if ep>-1 then begin
    if not TryStrToInt(a.Substring(ep+1),e) then
      raise Exception.Create(StrBadNumberFormat);
    a := a.Remove(ep);
  end else e := 0;
  dp := a.IndexOf('.');
  if dp=-1 then dp := a.Length;
  for j := 0 to dp-1 do
    if not(a.Chars[j] in ['0'..'9']) then
      raise Exception.Create(StrBadNumberFormat);
  for j := dp+1 to a.Length-1 do
    if not(a.Chars[j] in ['0'..'9']) then
      raise Exception.Create(StrBadNumberFormat);
  a := a.Remove(dp,1);
  if a.Length=0 then raise Exception.Create(StrBadNumberFormat);
  Result.Power := floor(e / 9)+1;
  dp := dp+e-(Result.Power-1)*9;
  if dp<0 then begin
    a := a.PadLeft(a.Length-dp,'0');
    dp := 0;
  end else if dp>a.Length then a := a.PadRight(dp,'0');
  i := dp mod 9;
  SetLength(Result.DATA,(a.Length-i+8) div 9+ord(i>0));
  a:= a.PadRight((a.Length-i+8)div 9 * 9+i,'0');
  if i>0 then begin
    Result.DATA[0] := StrToUint(a.Substring(0,i));
    j:=1;
  end else j := 0;
  while i<a.Length do begin
    Result.DATA[j] := StrToUint(a.Substring(i,9));
    inc(j);
    inc(i,9);
  end;
  Result.TrimData;
end;

class operator BigData.Implicit(a: Double): BigData;
begin
  if a=0 then begin
    Result.Positive := 0;
    exit;
  end else if a<0 then begin
    Result.Positive := -1;
    a := -a;
  end else Result.Positive := 1;
  Result.Power := Floor(ln(a)/ln(1000000000))+1;
  a := Power10(a,-(Result.Power-1)*9);
  SetLength(Result.DATA,3);
  Result.Data[0] := trunc(a);
  a := (a-Result.DATA[0])*1000000000;
  Result.DATA[1] := trunc(a);
  a := (a-Result.DATA[1])*1000000000;
  Result.DATA[2] := trunc(a);
  Result.TrimData;
end;

class constructor BigData.InitBigData;
begin
  DefaultPrec := 2000;
end;

function BigData.ToString: String;
var S : TStringBuilder;
    i,j : integer;
begin
  if Positive=0 then exit('0');
  S := TStringBuilder.Create;
  if Positive<0 then S.Append('-');
  i := 0;
  if Power>0 then begin
    S.Append(Data[0]);
    i := 1;
    while (i<Power)and(i<Length(Data)) do begin
      S.Append(Data[i].ToString.PadLeft(9,'0'));
      inc(i);
    end;
    while i<Power do begin
      S.Append('000000000');
      inc(i);
    end;
  end else begin
    S.Append('0');
  end;
  if i<Length(Data) then S.Append('.');
  if Power<0 then begin
    i := Power;
    while i<0 do begin
      S.Append('000000000');
      inc(i);
    end;
  end;
  while i<Length(data)-1 do begin
    S.Append(Data[i].ToString.PadLeft(9,'0'));
    inc(i);
  end;
  if i>=Power then begin
    j := Data[i];
    while j Mod 10 = 0 do J := j div 10;
    S.Append(J.ToString);
  end;
  Result:= S.ToString;
end;

procedure BigData.TrimData;
var i : Cardinal;
    j : integer;
begin
  if Length(Data)=0 then begin
    Positive := 0;
    exit;
  end;
  i := 0;
  while (i<Length(Data))and(Data[i]=0) do inc(i);
  if i=Length(data) then begin
    Data := nil;
    Positive := 0;
  end else if i>0 then begin
    Move(Data[i],Data[0],SizeOf(Cardinal)*(Length(Data)-i));
    Power := Power -i;
  end;
  j := Length(Data)-1-i;
  while (j>0)and(Data[j]=0) do dec(j);
  SetLength(Data,j+1);
end;

class operator BigData.Explicit(a: BigData): int64;
var i : integer;
    j : UInt64;
begin
  i := a.Positive;
  try
    if i=-1 then a.Positive := 1;
    J := UInt64(a);
    if ((i=-1)and(J>$8000000000000000))or((i=1)and(J>$7fffffffffffffff)) then
      raise Exception.Create(StrBigDataTooBig);
    Result := i*J;
  finally
    a.Positive := i;
  end;
end;

class operator BigData.Implicit(a: Int64): BigData;
var c : UInt64;
begin
  if a<0 then begin
    c := -a;
    Result := c;
    Result.Positive := -1
  end else begin
    c := a;
    Result := c;
  end;
end;

class operator BigData.Explicit(a: BigData): Uint64;
const
  c1 = High(UInt64) div 1000000000000000000;
  c2 = (High(UInt64) mod 1000000000000000000) div 1000000000;
  c3 = High(UInt64) mod 1000000000;
var c : Cardinal;
begin
  if a.Positive<0 then raise Exception.Create(StrNegToUnSigned);
  if (a.Positive=0)or(a.Power<1) then exit(0);
  if a.Power>3 then raise Exception.Create(StrBigDataTooBig);
  if a.Power=1 then exit(a.DATA[0]);
  if a.Power=2 then exit(a.DATA[0]*1000000000+a.DATA[1]);
  if a.DATA[0]>c1 then
    raise Exception.Create(StrBigDataTooBig);
  if a.DATA[0]=c1 then begin
    if a.DATA[1]>c2 then raise Exception.Create(StrBigDataTooBig);
    if (a.DATA[1]=c2)and(a.DATA[2]>c3) then
      raise Exception.Create(StrBigDataTooBig);
  end;
  Result:=a.DATA[0]*1000000000000000000+a.DATA[1]*1000000000+a.DATA[2]
end;

class operator BigData.Explicit(a: BigData): Double;
var i,j : integer;
    d : double;
begin
  if a.Positive=0 then exit(0.0);
  i := 3;
  if i>Length(a.DATA) then i := Length(a.DATA);
  j := i-1;
  d := 1;
  Result := 0;
  repeat
    Result := Result+a.DATA[j]*d;
    d := d*1000000000;
    dec(j);
  until (j<0);
  Result := a.Positive*Power10(Result,(a.Power-i)*9);
end;

end.
