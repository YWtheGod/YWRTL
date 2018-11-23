unit YWRTLUtils;

interface

type
  TAttributeType = class of TCustomAttribute;

function GetStoredAttributeNames(T: TClass) : TArray<String>;
function GetClassesWithAttributes(T : TClass; S : String): TArray<TClass>; overload;
function GetClassesWithAttributes(T : TClass; S : TAttributeType): TArray<TClass>; overload;
function GetAttribute(T : TClass; S : TAttributeType): TCustomAttribute;
function GetAttributes(T : TClass; S : TAttributeType): TArray<TCustomAttribute>;

implementation
uses classes, sysutils, System.Rtti, Generics.Collections;

function GetAttribute(T : TClass; S : TAttributeType): TCustomAttribute;
var C : TRttiContext;
    I : TRttiType;
    A : TCustomAttribute;
begin
  Result := nil;
  C := TRttiContext.Create;
  try
    I := C.GetType(T);
    for A in I.GetAttributes do
    begin
      if A is S then begin
        Result := A;
        exit;
      end;
    end;
  finally
    C.Free;
  end;
end;

function GetAttributes(T : TClass; S : TAttributeType): TArray<TCustomAttribute>;
var C : TRttiContext;
    I : TRttiType;
    A : TCustomAttribute;
    N : integer;
begin
  SetLength(Result,0);
  N := 0;
  C := TRttiContext.Create;
  try
    I := C.GetType(T);
    for A in I.GetAttributes do
    begin
      if A is S then begin
        if N=Length(Result) then SetLength(Result,Length(Result)+20);
        Result[N] := A;
        inc(N);
      end;
    end;
  finally
    C.Free;
  end;
  SetLength(Result,N);
end;


function GetClassesWithAttributes(T : TClass; S : String): TArray<TClass>;
var C : TRttiContext;
    I : TRttiType;
    A : TCustomAttribute;
    S1,S2 : integer;
begin
  S := S.ToUpper.Trim;
  C := TRttiContext.Create;
  S1 := 0; S2 := 0;
  try
    for I in C.GetTypes do
    begin
      if I.IsInstance and I.AsInstance.MetaclassType.InheritsFrom(T) then begin
        for A in I.GetAttributes do
        begin
          if (A is StoredAttribute)and(StoredAttribute(A).Name.ToUpper.Trim=S)
          then begin
            if S1=S2 then begin
              inc(s2,20);
              setlength(Result,s2);
            end;
            Result[S1] := I.AsInstance.MetaclassType;
            inc(S1);
          end;
        end;
      end;
    end;
    setlength(Result,s1);
  finally
    C.Free;
  end;
end;

function GetClassesWithAttributes(T : TClass; S : TAttributeType): TArray<TClass>;
var C : TRttiContext;
    I : TRttiType;
    A : TCustomAttribute;
    S1,S2 : integer;
begin
  C := TRttiContext.Create;
  S1 := 0; S2 := 0;
  try
    for I in C.GetTypes do
    begin
      if I.IsInstance and I.AsInstance.MetaclassType.InheritsFrom(T) then begin
        for A in I.GetAttributes do
        begin
          if A is S then begin
            if S1=S2 then begin
              inc(s2,20);
              setlength(Result,s2);
            end;
            Result[S1] := I.AsInstance.MetaclassType;
            inc(S1);
          end;
        end;
      end;
    end;
    setlength(Result,s1);
  finally
    C.Free;
  end;
end;

function GetStoredAttributeNames(T:TClass) : TArray<String>;
var C : TRttiContext;
    I : TRttiType;
    A : TCustomAttribute;
    S1,S2 : integer;
begin
  C := TRttiContext.Create;
  s1 := 0; s2 := 0;
  try
    I := C.GetType(T);
    for A in I.GetAttributes do
    begin
      if A is StoredAttribute then begin
        if s1=s2 then begin
          inc(s2,20);
          setlength(Result,s2);
        end;
        Result[s1] := StoredAttribute(A).Name;
        inc(s1);
      end;
    end;
    SetLength(Result,s1);
  finally
    C.Free;
  end;
end;


end.
