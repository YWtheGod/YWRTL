unit UniARC;

interface
{$IFNDEF AUTOREFCOUNT}
type
  R<T : class> =record
  private
    GuardRef : IUnknown;
  public
    function O : T; inline;
    class operator Implicit(a: T): R<T>; inline;
    class operator Implicit(a: R<T>): T; inline;
    class operator Equal(a, b: R<T>) : Boolean;  inline;
    class operator NotEqual(a, b: R<T>) : Boolean;  inline;
    class operator Equal(a : R<T>; b: Pointer) : Boolean;  inline;
    class operator NotEqual(a : R<T>; b: Pointer) : Boolean;  inline;
    class operator Equal(a : R<T>; b: T) : Boolean;  inline;
    class operator NotEqual(a : R<T>; b: T) : Boolean;  inline;
    class operator Positive(a: R<T>): T; inline;
  end;

  WR<T : class> =record
  private
    DataRef : IUnknown;
  public
    function O : T; inline;
    class operator Implicit(a: WR<T>): R<T>; inline;
    class operator Implicit(a: R<T>): WR<T>; inline;
    class operator Equal(a, b: WR<T>) : Boolean; inline;
    class operator NotEqual(a, b: WR<T>) : Boolean;  inline;
    class operator Equal(a : WR<T>; b: Pointer) : Boolean;  inline;
    class operator NotEqual(a : WR<T>; b: Pointer) : Boolean;  inline;
    class operator Equal(a : WR<T>; b: T) : Boolean;  inline;
    class operator NotEqual(a : WR<T>; b: T) : Boolean;  inline;
    class operator Equal(a : WR<T>; b: R<T>) : Boolean;  inline;
    class operator NotEqual(a : WR<T>; b: R<T>) : Boolean;  inline;
    class operator Positive(a: WR<T>): T; inline;
  end;

  __TGuard<T : class> = class(TInterfacedObject)
    obj : T;
    DataRef : IUnknown;
    constructor Create(a : T);
    destructor Destroy; override;
  end;

  __TGuardData<T : class> = class(TInterfacedObject)
    Guard : __TGuard<T>;
    constructor Create(G : __TGuard<T>);
  end;
{$ELSE}
type
  R<T : class> =record
  private
    obj : T;
  public
    function O : T; inline;
    class operator Implicit(a: T): R<T>; inline;
    class operator Implicit(a: R<T>): T; inline;
    class operator Equal(a, b: R<T>) : Boolean;  inline;
    class operator NotEqual(a, b: R<T>) : Boolean;  inline;
    class operator Equal(a : R<T>; b: Pointer) : Boolean;  inline;
    class operator NotEqual(a : R<T>; b: Pointer) : Boolean;  inline;
    class operator Equal(a : R<T>; b: T) : Boolean;  inline;
    class operator NotEqual(a : R<T>; b: T) : Boolean;  inline;
    class operator Positive(a: R<T>): T; inline;
  end;

  WR<T : class> =record
  private
  [WEAK] obj : T;
  public
    function O : T; inline;
    class operator Implicit(a: WR<T>): R<T>; inline;
    class operator Implicit(a: R<T>): WR<T>; inline;
    class operator Equal(a, b: WR<T>) : Boolean; inline;
    class operator NotEqual(a, b: WR<T>) : Boolean;  inline;
    class operator Equal(a : WR<T>; b: Pointer) : Boolean;  inline;
    class operator NotEqual(a : WR<T>; b: Pointer) : Boolean;  inline;
    class operator Equal(a : WR<T>; b: T) : Boolean;  inline;
    class operator NotEqual(a : WR<T>; b: T) : Boolean;  inline;
    class operator Equal(a : WR<T>; b: R<T>) : Boolean;  inline;
    class operator NotEqual(a : WR<T>; b: R<T>) : Boolean;  inline;
    class operator Positive(a: WR<T>): T; inline;
  end;
{$ENDIF}
implementation

{$IFNDEF AUTOREFCOUNT}
{ Guard<T> }

class operator R<T>.Implicit(a: T): R<T>;
begin
  if assigned(a) then Result.GuardRef := __TGuard<T>.Create(a)
  else Result.GuardRef := nil;
end;

class operator R<T>.Equal(a, b: R<T>): Boolean;
begin
  Result := a.GuardRef = b.GuardRef;
end;

class operator R<T>.Equal(a: R<T>; b:Pointer): Boolean;
begin
  Result := Pointer(a.O)=b;
end;

class operator R<T>.Equal(a: R<T>; b: T): Boolean;
begin
  Result := a.O = b;
end;

class operator R<T>.Implicit(a: R<T>): T;
begin
  Result := a.O;
end;

class operator R<T>.NotEqual(a: R<T>; b: Pointer): Boolean;
begin
  Result := Pointer(a.O)<>b;
end;

class operator R<T>.NotEqual(a, b: R<T>): Boolean;
begin
  Result := a.GuardRef<>b.GuardRef;
end;

class operator R<T>.NotEqual(a: R<T>; b: T): Boolean;
begin
  Result := a.O<>b;
end;

function R<T>.O: T;
begin
  if GuardRef=nil then Result := nil
  else Result := __TGuard<T>(GuardRef).obj;
end;

class operator R<T>.Positive(a: R<T>): T;
begin
  Result := a.O;
end;

{ TGuard<T> }

constructor __TGuard<T>.Create(a: T);
begin
  inherited Create;
  obj := a;
end;

destructor __TGuard<T>.Destroy;
begin
  if assigned(DataRef) then begin
    __TGuardData<T>(DataRef).Guard := nil;
  end;
  obj.DisposeOf;
  inherited;
end;

{ TWeakGuard<T> }

constructor __TGuardData<T>.Create(G : __TGuard<T>);
begin
  inherited Create;
  Guard := G;
end;

{ WG<T> }

class operator WR<T>.Implicit(a: WR<T>): R<T>;
begin
  if assigned(a.DataRef) then
    Result.GuardRef := __TGuardData<T>(a.DataRef).Guard
  else Result.GuardRef := nil;
end;

class operator WR<T>.Equal(a, b: WR<T>): Boolean;
begin
  Result := a.DataRef = b.DataRef;
end;

class operator WR<T>.Equal(a: WR<T>; b:Pointer): Boolean;
begin
  Result := Pointer(a.O)=b;
end;

class operator WR<T>.Equal(a: WR<T>; b: T): Boolean;
begin
  Result := a.O = b;
end;

class operator WR<T>.Equal(a: WR<T>; b: R<T>): Boolean;
begin
  Result := a.O = b.O;
end;

class operator WR<T>.Implicit(a: R<T>): WR<T>;
begin
  if assigned(a.GuardRef) then begin
    if __TGuard<T>(a.GuardRef).DataRef=nil then
      __TGuard<T>(a.GuardRef).DataRef := __TGuardData<T>
        .Create(__TGuard<T>(a.GuardRef));
    Result.DataRef := __TGuard<T>(a.GuardRef).DataRef;
  end else Result.DataRef := nil;
end;

class operator WR<T>.NotEqual(a: WR<T>; b: Pointer): Boolean;
begin
  Result := Pointer(a.O)<>b;
end;

class operator WR<T>.NotEqual(a, b: WR<T>): Boolean;
begin
  Result := a.DataRef<>b.DataRef;
end;

class operator WR<T>.NotEqual(a: WR<T>; b: T): Boolean;
begin
  Result := a.O<>b;
end;

class operator WR<T>.NotEqual(a: WR<T>; b: R<T>): Boolean;
begin
  Result := a.O<>b.O;
end;

function WR<T>.O: T;
begin
  if (DataRef=nil)or(__TGuardData<T>(DataRef).Guard=nil) then Result := nil
  else Result := __TGuardData<T>(DataRef).Guard.obj;
end;

class operator WR<T>.Positive(a: WR<T>): T;
begin
  Result := a.O;
end;
{$ELSE}
{ Guard<T> }

class operator R<T>.Implicit(a: T): R<T>;
begin
  Result.obj := a;
end;

class operator R<T>.Equal(a, b: R<T>): Boolean;
begin
  Result := a.obj = b.obj;
end;

class operator R<T>.Equal(a: R<T>; b: Pointer): Boolean;
begin
  Result := Pointer(a.obj)=b;
end;

class operator R<T>.Equal(a: R<T>; b: T): Boolean;
begin
  Result := a.obj = b;
end;

class operator R<T>.Implicit(a: R<T>): T;
begin
  Result := a.O;
end;

class operator R<T>.NotEqual(a, b: R<T>): Boolean;
begin
  Result := a.obj<>b.obj;
end;

class operator R<T>.NotEqual(a: R<T>; b: Pointer): Boolean;
begin
  Result := Pointer(a.obj)<>b;
end;

class operator R<T>.NotEqual(a: R<T>; b: T): Boolean;
begin
  Result := a.obj <>b;
end;

function R<T>.O: T;
begin
  Result := obj;
end;

class operator R<T>.Positive(a: R<T>): T;
begin
  Result := a.O;
end;

{ WG<T> }

class operator WR<T>.Implicit(a: WR<T>): R<T>;
begin
  Result.obj := a.obj;
end;

class operator WR<T>.Equal(a, b: WR<T>): Boolean;
begin
  Result := a.obj = b.obj;
end;

class operator WR<T>.Equal(a: WR<T>; b: Pointer): Boolean;
begin
  Result := Pointer(a.obj) = b;
end;

class operator WR<T>.Equal(a: WR<T>; b: T): Boolean;
begin
  Result := a.obj = b;
end;

class operator WR<T>.Equal(a: WR<T>; b: R<T>): Boolean;
begin
  Result := a.obj = b.obj;
end;

class operator WR<T>.Implicit(a: R<T>): WR<T>;
begin
  Result.obj := a.obj;
end;

class operator WR<T>.NotEqual(a, b: WR<T>): Boolean;
begin
  Result := a.obj <> b.obj;
end;

class operator WR<T>.NotEqual(a: WR<T>; b: Pointer): Boolean;
begin
  Result := Pointer(a.obj)<>b;
end;

class operator WR<T>.NotEqual(a: WR<T>; b: T): Boolean;
begin
  Result := a.obj <>b;
end;

class operator WR<T>.NotEqual(a: WR<T>; b: R<T>): Boolean;
begin
  Result := a.obj<>b.obj;
end;

function WR<T>.O: T;
begin
  Result := obj;
end;

class operator WR<T>.Positive(a: WR<T>): T;
begin
  Result := a.O;
end;
{$ENDIF}

end.
