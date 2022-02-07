unit YWDictionarys;

interface
uses classes, SysUtils, RTLConsts, Generics.Collections, Generics.Defaults;
type
  TModDictionary<TKey,TValue,TItem> = class abstract(TEnumerable<TPair<TKey,TValue>>)
  private
  type
    TItemArray = array of TItem;
  var
    FItems: TItemArray;
    FCount: Integer;
    FComparer: IEqualityComparer<TKey>;
    FGrowThreshold: Integer;

    function ToArrayImpl(Count: Integer): TArray<TPair<TKey,TValue>>;
    procedure SetCapacity(ACapacity: Integer);
    procedure Rehash(NewCapPow2: Integer);
    procedure Grow;
    function GetBucketIndex(const Key: TKey; HashCode: Integer): Integer;
    function GetItem(const Key: TKey): TValue;
    procedure SetItem(const Key: TKey; const Value: TValue);
    procedure RehashAdd(HashCode: Integer; const Key: TKey; const Value: TValue);
    procedure DoAdd(HashCode, Index: Integer; const Key: TKey; const Value: TValue);
    procedure DoSetValue(Index: Integer; const Value: TValue);
    function DoRemove(const Key: TKey; HashCode: Integer; Notification: TCollectionNotification): TValue;
  protected
    function DoGetEnumerator: TEnumerator<TPair<TKey,TValue>>; override;
    procedure KeyNotify(const Key: TKey; Action: TCollectionNotification); virtual;
    procedure ValueNotify(const Value: TValue; Action: TCollectionNotification); virtual;
    procedure SetHashCodeForItem(var I : TItem; H : integer); virtual; abstract;
    function GetHashCodeFromItem(var I : TItem):integer; virtual; abstract;
    procedure SetKeyForItem(var I : TItem; H : TKey); virtual; abstract;
    function GetKeyFromItem(var I : TItem):TKey; virtual; abstract;
    procedure SetValueForItem(var I : TItem; H : TValue); virtual; abstract;
    function GetValueFromItem(var I : TItem):TValue; virtual; abstract;
    function Hash(const Key: TKey): Integer; virtual;
  public
    constructor Create(ACapacity: Integer = 0); overload;
    constructor Create(const AComparer: IEqualityComparer<TKey>); overload;
    constructor Create(ACapacity: Integer; const AComparer: IEqualityComparer<TKey>); overload;
    constructor Create(const Collection: TEnumerable<TPair<TKey,TValue>>); overload;
    constructor Create(const Collection: TEnumerable<TPair<TKey,TValue>>; const AComparer: IEqualityComparer<TKey>); overload;
    destructor Destroy; override;

    procedure Add(const Key: TKey; const Value: TValue);
    procedure Remove(const Key: TKey);
    function ExtractPair(const Key: TKey): TPair<TKey,TValue>;
    procedure Clear;
    procedure TrimExcess;
    function TryGetValue(const Key: TKey; out Value: TValue): Boolean;
    procedure AddOrSetValue(const Key: TKey; const Value: TValue);
    function TryAdd(const Key: TKey; const Value: TValue): Boolean;
    function ContainsKey(const Key: TKey): Boolean;
    function ContainsValue(const Value: TValue): Boolean;
    function ToArray: TArray<TPair<TKey,TValue>>; override; final;

    property Items[const Key: TKey]: TValue read GetItem write SetItem; default;
    property Count: Integer read FCount;

    type
      TPairEnumerator = class(TEnumerator<TPair<TKey,TValue>>)
      private
        FDictionary: TModDictionary<TKey,TValue,TItem>;
        FIndex: Integer;
        function GetCurrent: TPair<TKey,TValue>;
      protected
        function DoGetCurrent: TPair<TKey,TValue>; override;
        function DoMoveNext: Boolean; override;
      public
        constructor Create(const ADictionary: TModDictionary<TKey,TValue,TItem>);
        property Current: TPair<TKey,TValue> read GetCurrent;
        function MoveNext: Boolean;
      end;

      TKeyEnumerator = class(TEnumerator<TKey>)
      private
        FDictionary: TModDictionary<TKey,TValue,TItem>;
        FIndex: Integer;
        function GetCurrent: TKey;
      protected
        function DoGetCurrent: TKey; override;
        function DoMoveNext: Boolean; override;
      public
        constructor Create(const ADictionary: TModDictionary<TKey,TValue,TItem>);
        property Current: TKey read GetCurrent;
        function MoveNext: Boolean;
      end;

      TValueEnumerator = class(TEnumerator<TValue>)
      private
        FDictionary: TModDictionary<TKey,TValue,TItem>;
        FIndex: Integer;
        function GetCurrent: TValue;
      protected
        function DoGetCurrent: TValue; override;
        function DoMoveNext: Boolean; override;
      public
        constructor Create(const ADictionary: TModDictionary<TKey,TValue,TItem>);
        property Current: TValue read GetCurrent;
        function MoveNext: Boolean;
      end;

      TValueCollection = class(TEnumerable<TValue>)
      private
        [Weak] FDictionary: TModDictionary<TKey,TValue,TItem>;
        function GetCount: Integer;
        function ToArrayImpl(Count: Integer): TArray<TValue>;
      protected
        function DoGetEnumerator: TEnumerator<TValue>; override;
      public
        constructor Create(const ADictionary: TModDictionary<TKey,TValue,TItem>);
        function GetEnumerator: TValueEnumerator; reintroduce;
        function ToArray: TArray<TValue>; override; final;
        property Count: Integer read GetCount;
      end;

      TKeyCollection = class(TEnumerable<TKey>)
      private
        [Weak] FDictionary: TModDictionary<TKey,TValue,TItem>;
        function GetCount: Integer;
        function ToArrayImpl(Count: Integer): TArray<TKey>;
      protected
        function DoGetEnumerator: TEnumerator<TKey>; override;
      public
        constructor Create(const ADictionary: TModDictionary<TKey,TValue,TItem>);
        function GetEnumerator: TKeyEnumerator; reintroduce;
        function ToArray: TArray<TKey>; override; final;
        property Count: Integer read GetCount;
      end;

  private
    FOnKeyNotify: TCollectionNotifyEvent<TKey>;
    FOnValueNotify: TCollectionNotifyEvent<TValue>;
    FKeyCollection: TKeyCollection;
    FValueCollection: TValueCollection;
    function GetKeys: TKeyCollection;
    function GetValues: TValueCollection;
  public
    function GetEnumerator: TPairEnumerator; reintroduce;
    property Keys: TKeyCollection read GetKeys;
    property Values: TValueCollection read GetValues;
    property Comparer: IEqualityComparer<TKey> read FComparer;
    property OnKeyNotify: TCollectionNotifyEvent<TKey> read FOnKeyNotify write FOnKeyNotify;
    property OnValueNotify: TCollectionNotifyEvent<TValue> read FOnValueNotify write FOnValueNotify;
  end;

  _TGUIDItem<TValue> = record
    Key : TGuid;
    Value : TValue;
  end;

  TGUIDDictionary<TValue>=class(TModDictionary<TGuid,TValue,_TGUIDItem<TValue>>)
  protected
    procedure SetHashCodeForItem(var I : _TGUIDItem<TValue>; H : integer); override;
    function GetHashCodeFromItem(var I : _TGUIDItem<TValue>):integer; override;
    procedure SetKeyForItem(var I : _TGUIDItem<TValue>; H : TGUID); override;
    function GetKeyFromItem(var I : _TGUIDItem<TValue>):TGUID; override;
    procedure SetValueForItem(var I : _TGUIDItem<TValue>; H : TValue); override;
    function GetValueFromItem(var I : _TGUIDItem<TValue>):TValue; override;
    function Hash(const Key: TGUID): Integer; override;
  end;

  _TKeyedObjItem<TValue> = record
    HashCode : integer;
    Value : TValue;
  end;

  TKeyedObjDictionary<TKey,TValue>= class abstract(TModDictionary<TKey,TValue,_TKeyedObjItem<TValue>>)
  protected
    function GetKeyFromValue(V : TValue):TKey; virtual; abstract;
    procedure SetHashCodeForItem(var I : _TKeyedObjItem<TValue>; H : integer); override;
    function GetHashCodeFromItem(var I : _TKeyedObjItem<TValue>):integer; override;
    procedure SetKeyForItem(var I : _TKeyedObjItem<TValue>; H : TKey); override;
    function GetKeyFromItem(var I : _TKeyedObjItem<TValue>):TKey; override;
    procedure SetValueForItem(var I : _TKeyedObjItem<TValue>; H : TValue); override;
    function GetValueFromItem(var I : _TKeyedObjItem<TValue>):TValue; override;
  end;

  TGUIDedObjDictionary<TValue>=class abstract(TKeyedObjDictionary<TGuid,TValue>)
  protected
    function Hash(const Key: TGUID): Integer; override;
  end;

function InCircularRange(Bottom, Item, TopInc: Integer): Boolean; inline;

implementation
const
  EMPTY_HASH = -1;

procedure TModDictionary<TKey,TValue,TItem>.Rehash(NewCapPow2: Integer);
var
  oldItems, newItems: TItemArray;
  i: Integer;
begin
  if NewCapPow2 = Length(FItems) then
    Exit
  else if NewCapPow2 < 0 then
    OutOfMemoryError;

  oldItems := FItems;
  SetLength(newItems, NewCapPow2);
  for i := 0 to Length(newItems) - 1 do
    SetHashCodeForItem(newItems[i],EMPTY_HASH);
  FItems := newItems;
  FGrowThreshold := NewCapPow2 shr 1 + NewCapPow2 shr 2; // 75%

  for i := 0 to Length(oldItems) - 1 do
    if GetHashCodeFromItem(oldItems[i]) <> EMPTY_HASH then
      RehashAdd(GetHashCodeFromItem(oldItems[i]), GetKeyFromItem(oldItems[i]),
        GetValueFromItem(oldItems[i]));
end;

procedure TModDictionary<TKey,TValue,TItem>.SetCapacity(ACapacity: Integer);
var
  newCap: Integer;
begin
  if ACapacity < Count then
    ErrorArgumentOutOfRange;

  if ACapacity = 0 then
    Rehash(0)
  else
  begin
    newCap := 4;
    while newCap < ACapacity do
      newCap := newCap shl 1;
    Rehash(newCap);
  end
end;

procedure TModDictionary<TKey,TValue,TItem>.Grow;
var
  newCap: Integer;
begin
  newCap := Length(FItems) * 2;
  if newCap = 0 then
    newCap := 4;
  Rehash(newCap);
end;

function TModDictionary<TKey,TValue,TItem>.GetBucketIndex(const Key: TKey; HashCode: Integer): Integer;
var
  start, hc: Integer;
begin
  if Length(FItems) = 0 then
    Exit(not High(Integer));

  start := HashCode and (Length(FItems) - 1);
  Result := start;
  while True do
  begin
    hc := GetHashCodeFromItem(FItems[Result]);

    // Not found: return complement of insertion point.
    if hc = EMPTY_HASH then
      Exit(not Result);

    // Found: return location.
    if (hc = HashCode) and FComparer.Equals(GetKeyFromItem(FItems[Result]), Key) then
      Exit(Result);

    Inc(Result);
    if Result >= Length(FItems) then
      Result := 0;
  end;
end;

function TModDictionary<TKey,TValue,TItem>.Hash(const Key: TKey): Integer;
const
  PositiveMask = not Integer($80000000);
begin
  // Double-Abs to avoid -MaxInt and MinInt problems.
  // Not using compiler-Abs because we *must* get a positive integer;
  // for compiler, Abs(Low(Integer)) is a null op.
  Result := PositiveMask and ((PositiveMask and FComparer.GetHashCode(Key)) + 1);
end;

function TModDictionary<TKey,TValue,TItem>.GetItem(const Key: TKey): TValue;
var
  index: Integer;
begin
  index := GetBucketIndex(Key, Hash(Key));
  if index < 0 then
    raise EListError.CreateRes(@SGenericItemNotFound);
  Result := GetValueFromItem(FItems[index]);
end;

procedure TModDictionary<TKey,TValue,TItem>.SetItem(const Key: TKey; const Value: TValue);
var
  index: Integer;
  oldValue: TValue;
begin
  index := GetBucketIndex(Key, Hash(Key));
  if index < 0 then
    raise EListError.CreateRes(@SGenericItemNotFound);

  oldValue := GetValueFromItem(FItems[index]);
  SetValueForItem(FItems[index],Value);

  ValueNotify(oldValue, cnRemoved);
  ValueNotify(Value, cnAdded);
end;

procedure TModDictionary<TKey,TValue,TItem>.RehashAdd(HashCode: Integer; const Key: TKey; const Value: TValue);
var
  index: Integer;
begin
  index := not GetBucketIndex(Key, HashCode);
  SetHashCodeForItem(FItems[index],HashCode);
  SetKeyForItem(FItems[index],Key);
  SetValueForItem(FItems[index],Value);
end;

procedure TModDictionary<TKey,TValue,TItem>.KeyNotify(const Key: TKey; Action: TCollectionNotification);
begin
  if Assigned(FOnKeyNotify) then
    FOnKeyNotify(Self, Key, Action);
end;

procedure TModDictionary<TKey,TValue,TItem>.ValueNotify(const Value: TValue; Action: TCollectionNotification);
begin
  if Assigned(FOnValueNotify) then
    FOnValueNotify(Self, Value, Action);
end;

constructor TModDictionary<TKey,TValue,TItem>.Create(ACapacity: Integer = 0);
begin
  Create(ACapacity, nil);
end;

constructor TModDictionary<TKey,TValue,TItem>.Create(const AComparer: IEqualityComparer<TKey>);
begin
  Create(0, AComparer);
end;

constructor TModDictionary<TKey,TValue,TItem>.Create(ACapacity: Integer; const AComparer: IEqualityComparer<TKey>);
var
  cap: Integer;
begin
  inherited Create;
  if ACapacity < 0 then
    ErrorArgumentOutOfRange;
  FComparer := AComparer;
  if FComparer = nil then
    FComparer := TEqualityComparer<TKey>.Default;
  SetCapacity(ACapacity);
end;

constructor TModDictionary<TKey, TValue,TItem>.Create(const Collection: TEnumerable<TPair<TKey, TValue>>);
var
  item: TPair<TKey,TValue>;
begin
  Create(0, nil);
  for item in Collection do
    AddOrSetValue(item.Key, item.Value);
end;

constructor TModDictionary<TKey, TValue,TItem>.Create(const Collection: TEnumerable<TPair<TKey, TValue>>;
  const AComparer: IEqualityComparer<TKey>);
var
  item: TPair<TKey,TValue>;
begin
  Create(0, AComparer);
  for item in Collection do
    AddOrSetValue(item.Key, item.Value);
end;

destructor TModDictionary<TKey,TValue,TItem>.Destroy;
begin
  Clear;
  FKeyCollection.Free;
  FValueCollection.Free;
  inherited;
end;

procedure TModDictionary<TKey,TValue,TItem>.Add(const Key: TKey; const Value: TValue);
var
  index, hc: Integer;
begin
  if Count >= FGrowThreshold then
    Grow;

  hc := Hash(Key);
  index := GetBucketIndex(Key, hc);
  if index >= 0 then
    raise EListError.CreateRes(@SGenericDuplicateItem);

  DoAdd(hc, not index, Key, Value);
end;

function InCircularRange(Bottom, Item, TopInc: Integer): Boolean;
begin
  Result := (Bottom < Item) and (Item <= TopInc) // normal
    or (TopInc < Bottom) and (Item > Bottom) // top wrapped
    or (TopInc < Bottom) and (Item <= TopInc) // top and item wrapped
end;

function TModDictionary<TKey,TValue,TItem>.DoRemove(const Key: TKey; HashCode: Integer;
  Notification: TCollectionNotification): TValue;
var
  gap, index, hc, bucket: Integer;
  LKey: TKey;
begin
  index := GetBucketIndex(Key, HashCode);
  if index < 0 then
    Exit(Default(TValue));

  // Removing item from linear probe hash table is moderately
  // tricky. We need to fill in gaps, which will involve moving items
  // which may not even hash to the same location.
  // Knuth covers it well enough in Vol III. 6.4.; but beware, Algorithm R
  // (2nd ed) has a bug: step R4 should go to step R1, not R2 (already errata'd).
  // My version does linear probing forward, not backward, however.

  // gap refers to the hole that needs filling-in by shifting items down.
  // index searches for items that have been probed out of their slot,
  // but being careful not to move items if their bucket is between
  // our gap and our index (so that they'd be moved before their bucket).
  // We move the item at index into the gap, whereupon the new gap is
  // at the index. If the index hits a hole, then we're done.

  // If our load factor was exactly 1, we'll need to hit this hole
  // in order to terminate. Shouldn't normally be necessary, though.
  SetHashCodeForItem(FItems[index],EMPTY_HASH);
  Result := GetValueFromItem(FItems[index]);
  LKey := GetKeyFromItem(FItems[index]);

  gap := index;
  while True do
  begin
    Inc(index);
    if index = Length(FItems) then
      index := 0;

    hc := GetHashCodeFromItem(FItems[index]);
    if hc = EMPTY_HASH then
      Break;

    bucket := hc and (Length(FItems) - 1);
    if not InCircularRange(gap, bucket, index) then
    begin
      FItems[gap] := FItems[index];
      gap := index;
      // The gap moved, but we still need to find it to terminate.
      SetHashCodeForItem(FItems[gap],EMPTY_HASH);
    end;
  end;

  SetHashCodeForItem(FItems[gap],EMPTY_HASH);
  SetKeyForItem(FItems[gap],Default(TKey));
  SetValueForItem(FItems[gap],Default(TValue));
  Dec(FCount);

  KeyNotify(LKey, Notification);
  ValueNotify(Result, Notification);
end;

procedure TModDictionary<TKey,TValue,TItem>.Remove(const Key: TKey);
begin
  DoRemove(Key, Hash(Key), cnRemoved);
end;

function TModDictionary<TKey,TValue,TItem>.ExtractPair(const Key: TKey): TPair<TKey,TValue>;
var
  hc, index: Integer;
begin
  hc := Hash(Key);
  index := GetBucketIndex(Key, hc);
  if index < 0 then
    Exit(TPair<TKey,TValue>.Create(Key, Default(TValue)));

  Result := TPair<TKey,TValue>.Create(Key, DoRemove(Key, hc, cnExtracted));
end;

procedure TModDictionary<TKey,TValue,TItem>.Clear;
var
  i: Integer;
  oldItems: TItemArray;
begin
  oldItems := FItems;
  FCount := 0;
  SetLength(FItems, 0);
  SetCapacity(0);
  FGrowThreshold := 0;

  for i := 0 to Length(oldItems) - 1 do
  begin
    if GetHashCodeFromItem(oldItems[i]) = EMPTY_HASH then
      Continue;
    KeyNotify(GetKeyFromItem(oldItems[i]), cnRemoved);
    ValueNotify(GetValueFromItem(oldItems[i]), cnRemoved);
  end;
end;

function TModDictionary<TKey, TValue,TItem>.ToArray: TArray<TPair<TKey,TValue>>;
begin
  Result := ToArrayImpl(Count);
end;

function TModDictionary<TKey, TValue, TItem>.ToArrayImpl(
  Count: Integer): TArray<TPair<TKey, TValue>>;
var
  Value: TPair<TKey, TValue>;
begin
  // We assume our caller has passed correct Count
  SetLength(Result, Count);
  Count := 0;
  for Value in Self do
  begin
    Result[Count] := Value;
    Inc(Count);
  end;
end;

procedure TModDictionary<TKey,TValue,TItem>.TrimExcess;
begin
  // Ensure at least one empty slot for GetBucketIndex to terminate.
  SetCapacity(Count + 1);
end;

function TModDictionary<TKey,TValue,TItem>.TryGetValue(const Key: TKey; out Value: TValue): Boolean;
var
  index: Integer;
begin
  index := GetBucketIndex(Key, Hash(Key));
  Result := index >= 0;
  if Result then
    Value := GetValueFromItem(FItems[index])
  else
    Value := Default(TValue);
end;

procedure TModDictionary<TKey,TValue,TItem>.DoAdd(HashCode, Index: Integer; const Key: TKey; const Value: TValue);
begin
  SetHashCodeForItem(FItems[Index],HashCode);
  SetKeyForItem(FItems[Index],Key);
  SetValueForItem(FItems[Index],Value);
  Inc(FCount);

  KeyNotify(Key, cnAdded);
  ValueNotify(Value, cnAdded);
end;

function TModDictionary<TKey, TValue,TItem>.DoGetEnumerator: TEnumerator<TPair<TKey, TValue>>;
begin
  Result := GetEnumerator;
end;

procedure TModDictionary<TKey,TValue,TItem>.DoSetValue(Index: Integer; const Value: TValue);
var
  oldValue: TValue;
begin
  oldValue := GetValueFromItem(FItems[Index]);
  SetValueForItem(FItems[Index],Value);

  ValueNotify(oldValue, cnRemoved);
  ValueNotify(Value, cnAdded);
end;

procedure TModDictionary<TKey,TValue,TItem>.AddOrSetValue(const Key: TKey; const Value: TValue);
var
  hc: Integer;
  index: Integer;
begin
  hc := Hash(Key);
  index := GetBucketIndex(Key, hc);
  if index >= 0 then
    DoSetValue(index, Value)
  else
  begin
    // We only grow if we are inserting a new value.
    if Count >= FGrowThreshold then
    begin
      Grow;
      // We need a new Bucket Index because the array has grown.
      index := GetBucketIndex(Key, hc);
    end;
    DoAdd(hc, not index, Key, Value);
  end;
end;

function TModDictionary<TKey,TValue,TItem>.TryAdd(const Key: TKey; const Value: TValue): Boolean;
var
  hc: Integer;
  index: Integer;
begin
  hc := Hash(Key);
  index := GetBucketIndex(Key, hc);
  Result := index < 0;
  if Result then
  begin
    // We only grow if we are inserting a new value.
    if Count >= FGrowThreshold then
    begin
      Grow;
      // We need a new Bucket Index because the array has grown.
      index := GetBucketIndex(Key, hc);
    end;
    DoAdd(hc, not index, Key, Value);
  end;
end;

function TModDictionary<TKey,TValue,TItem>.ContainsKey(const Key: TKey): Boolean;
begin
  Result := GetBucketIndex(Key, Hash(Key)) >= 0;
end;

function TModDictionary<TKey,TValue,TItem>.ContainsValue(const Value: TValue): Boolean;
var
  i: Integer;
  c: IEqualityComparer<TValue>;
begin
  c := TEqualityComparer<TValue>.Default;

  for i := 0 to Length(FItems) - 1 do
    if (GetHashCodeFromItem(FItems[i]) <> EMPTY_HASH) and
      c.Equals(GetValueFromItem(FItems[i]), Value) then
      Exit(True);
  Result := False;
end;

function TModDictionary<TKey,TValue,TItem>.GetEnumerator: TPairEnumerator;
begin
  Result := TPairEnumerator.Create(Self);
end;

function TModDictionary<TKey,TValue,TItem>.GetKeys: TKeyCollection;
begin
  if FKeyCollection = nil then
    FKeyCollection := TKeyCollection.Create(Self);
  Result := FKeyCollection;
end;

function TModDictionary<TKey,TValue,TItem>.GetValues: TValueCollection;
begin
  if FValueCollection = nil then
    FValueCollection := TValueCollection.Create(Self);
  Result := FValueCollection;
end;

// Pairs

constructor TModDictionary<TKey,TValue,TItem>.TPairEnumerator.Create(
  const ADictionary: TModDictionary<TKey,TValue,TItem>);
begin
  inherited Create;
  FIndex := -1;
  FDictionary := ADictionary;
end;

function TModDictionary<TKey, TValue,TItem>.TPairEnumerator.DoGetCurrent: TPair<TKey, TValue>;
begin
  Result := GetCurrent;
end;

function TModDictionary<TKey, TValue,TItem>.TPairEnumerator.DoMoveNext: Boolean;
begin
  Result := MoveNext;
end;

function TModDictionary<TKey,TValue,TItem>.TPairEnumerator.GetCurrent: TPair<TKey,TValue>;
begin
  Result.Key := FDictionary.GetKeyFromItem(FDictionary.FItems[FIndex]);
  Result.Value := FDictionary.GetValueFromItem(FDictionary.FItems[FIndex]);
end;

function TModDictionary<TKey,TValue,TItem>.TPairEnumerator.MoveNext: Boolean;
begin
  while FIndex < Length(FDictionary.FItems) - 1 do
  begin
    Inc(FIndex);
    if FDictionary.GetHashCodeFromItem(FDictionary.FItems[FIndex]) <> EMPTY_HASH then
      Exit(True);
  end;
  Result := False;
end;

// Keys

constructor TModDictionary<TKey,TValue,TItem>.TKeyEnumerator.Create(
  const ADictionary: TModDictionary<TKey,TValue,TItem>);
begin
  inherited Create;
  FIndex := -1;
  FDictionary := ADictionary;
end;

function TModDictionary<TKey, TValue,TItem>.TKeyEnumerator.DoGetCurrent: TKey;
begin
  Result := GetCurrent;
end;

function TModDictionary<TKey, TValue,TItem>.TKeyEnumerator.DoMoveNext: Boolean;
begin
  Result := MoveNext;
end;

function TModDictionary<TKey,TValue,TItem>.TKeyEnumerator.GetCurrent: TKey;
begin
  Result := FDictionary.GetKeyFromItem(FDictionary.FItems[FIndex]);
end;

function TModDictionary<TKey,TValue,TItem>.TKeyEnumerator.MoveNext: Boolean;
begin
  while FIndex < Length(FDictionary.FItems) - 1 do
  begin
    Inc(FIndex);
    if FDictionary.GetHashCodeFromItem(FDictionary.FItems[FIndex]) <> EMPTY_HASH then
      Exit(True);
  end;
  Result := False;
end;

// Values

constructor TModDictionary<TKey,TValue,TItem>.TValueEnumerator.Create(
  const ADictionary: TModDictionary<TKey,TValue,TItem>);
begin
  inherited Create;
  FIndex := -1;
  FDictionary := ADictionary;
end;

function TModDictionary<TKey, TValue,TItem>.TValueEnumerator.DoGetCurrent: TValue;
begin
  Result := GetCurrent;
end;

function TModDictionary<TKey, TValue,TItem>.TValueEnumerator.DoMoveNext: Boolean;
begin
  Result := MoveNext;
end;

function TModDictionary<TKey,TValue,TItem>.TValueEnumerator.GetCurrent: TValue;
begin
  Result := FDictionary.GetValueFromItem(FDictionary.FItems[FIndex]);
end;

function TModDictionary<TKey,TValue,TItem>.TValueEnumerator.MoveNext: Boolean;
begin
  while FIndex < Length(FDictionary.FItems) - 1 do
  begin
    Inc(FIndex);
    if FDictionary.GetHashCodeFromItem(FDictionary.FItems[FIndex]) <> EMPTY_HASH then
      Exit(True);
  end;
  Result := False;
end;

{ TGUIDDictionary<TValue> }

function TGUIDDictionary<TValue>.GetHashCodeFromItem(
  var I: _TGUIDItem<TValue>): integer;
begin
  Result := I.Key.D1;
end;

function TGUIDDictionary<TValue>.GetKeyFromItem(
  var I: _TGUIDItem<TValue>): TGUID;
begin
  Result := I.Key;
end;

function TGUIDDictionary<TValue>.GetValueFromItem(
  var I: _TGUIDItem<TValue>): TValue;
begin
  Result := I.Value;
end;

function TGUIDDictionary<TValue>.Hash(const Key: TGUID): Integer;
begin
  Result := Key.D1;
end;

procedure TGUIDDictionary<TValue>.SetHashCodeForItem(var I: _TGUIDItem<TValue>;
  H: integer);
begin
  I.Key.D1 := H;
end;

procedure TGUIDDictionary<TValue>.SetKeyForItem(var I: _TGUIDItem<TValue>;
  H: TGUID);
begin
  I.Key := H;
end;

procedure TGUIDDictionary<TValue>.SetValueForItem(var I: _TGUIDItem<TValue>;
  H: TValue);
begin
  I.Value := H;
end;

{ TKeyedObjDictionary<TKey, TValue> }

function TKeyedObjDictionary<TKey, TValue>.GetHashCodeFromItem(
  var I: _TKeyedObjItem<TValue>): integer;
begin
  Result := I.HashCode;
end;

function TKeyedObjDictionary<TKey, TValue>.GetKeyFromItem(
  var I: _TKeyedObjItem<TValue>): TKey;
begin
  Result := GetKeyFromValue(I.Value);
end;

function TKeyedObjDictionary<TKey, TValue>.GetValueFromItem(
  var I: _TKeyedObjItem<TValue>): TValue;
begin
  Result := I.Value;
end;

procedure TKeyedObjDictionary<TKey, TValue>.SetHashCodeForItem(
  var I: _TKeyedObjItem<TValue>; H: integer);
begin
  I.HashCode := H;
end;

procedure TKeyedObjDictionary<TKey, TValue>.SetKeyForItem(
  var I: _TKeyedObjItem<TValue>; H: TKey);
begin
end;

procedure TKeyedObjDictionary<TKey, TValue>.SetValueForItem(
  var I: _TKeyedObjItem<TValue>; H: TValue);
begin
  I.Value := H;
end;

{ TGUIDedObjDictionary<TValue> }

function TGUIDedObjDictionary<TValue>.Hash(const Key: TGUID): Integer;
begin
  Result := Key.D1;
end;

{ TModDictionary<TKey, TValue, TItem>.TValueCollection }

constructor TModDictionary<TKey, TValue, TItem>.TValueCollection.Create(
  const ADictionary: TModDictionary<TKey, TValue, TItem>);
begin
  inherited Create;
  FDictionary := ADictionary;
end;

function TModDictionary<TKey, TValue, TItem>.TValueCollection.DoGetEnumerator: TEnumerator<TValue>;
begin
  Result := GetEnumerator;
end;

function TModDictionary<TKey, TValue, TItem>.TValueCollection.GetCount: Integer;
begin
  Result := FDictionary.Count;
end;

function TModDictionary<TKey, TValue, TItem>.TValueCollection.GetEnumerator: TValueEnumerator;
begin
  Result := TValueEnumerator.Create(FDictionary);
end;

function TModDictionary<TKey, TValue, TItem>.TValueCollection.ToArray: TArray<TValue>;
begin
  Result := ToArrayImpl(FDictionary.Count);
end;

function TModDictionary<TKey, TValue, TItem>.TValueCollection.ToArrayImpl(
  Count: Integer): TArray<TValue>;
var
  Value: TValue;
begin
  // We assume our caller has passed correct Count
  SetLength(Result, Count);
  Count := 0;
  for Value in Self do
  begin
    Result[Count] := Value;
    Inc(Count);
  end;
end;

{ TModDictionary<TKey, TValue, TItem>.TKeyCollection }

constructor TModDictionary<TKey, TValue, TItem>.TKeyCollection.Create(
  const ADictionary: TModDictionary<TKey, TValue, TItem>);
begin
  inherited Create;
  FDictionary := ADictionary;
end;

function TModDictionary<TKey, TValue, TItem>.TKeyCollection.DoGetEnumerator: TEnumerator<TKey>;
begin
  Result := GetEnumerator;
end;

function TModDictionary<TKey, TValue, TItem>.TKeyCollection.GetCount: Integer;
begin
  Result := FDictionary.Count;
end;

function TModDictionary<TKey, TValue, TItem>.TKeyCollection.GetEnumerator: TKeyEnumerator;
begin
  Result := TKeyEnumerator.Create(FDictionary);
end;

function TModDictionary<TKey, TValue, TItem>.TKeyCollection.ToArray: TArray<TKey>;
begin
  Result := ToArrayImpl(FDictionary.Count);
end;

function TModDictionary<TKey, TValue, TItem>.TKeyCollection.ToArrayImpl(
  Count: Integer): TArray<TKey>;
var
  Value: TKey;
begin
  // We assume our caller has passed correct Count
  SetLength(Result, Count);
  Count := 0;
  for Value in Self do
  begin
    Result[Count] := Value;
    Inc(Count);
  end;
end;

end.
