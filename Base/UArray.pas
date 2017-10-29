{$mode objfpc}
{$modeswitch typehelpers}
{$modeswitch advancedrecords}

unit UArray;
interface
uses
	FPJSON, JSONParser, TypInfo,
	UString, UValue, UObject, UGeometry, SysUtils;


const
	kArrayInvalidIndex = -1;
	kArrayShrinks = true;
	kArrayLiteralSize = -1;
	
type
	TArrayIndex = integer;
	
const
	kArrayComparatorGreaterThan = kOrderedDescending;
	kArrayComparatorLessThan = kOrderedAscending;
	kArrayComparatorEqualTo = kOrderedSame;
	
type
	TArrayComparatorResult = integer;
	TArrayComparatorResultHelper = type helper for TArrayComparatorResult
		function GreaterThan: boolean;
		function LessThan: boolean;
		function GreaterThanOrEqualTo: boolean;
		function LessThanOrEqualTo: boolean;
		function EqualTo: boolean;
	end;

type
	generic TStaticArray<T> = class (TObject)
		public
			type
				TComparator = function (value1: T; value2: T; context: pointer): TArrayComparatorResult;
				TValuesArray = array of T;
		private
			type
				TArrayEnumerator = class
					private
						root: TStaticArray;
						currentValue: T;
					protected
						index: TArrayIndex;
					public
						constructor Create(_root: TStaticArray); 
						function MoveNext: Boolean;
						procedure Reset;
						property Current: T read currentValue;
				end;
		public		
		
			{ Class Methods }
			constructor ArrayWithArray (otherArray: TStaticArray);
			constructor ArrayWithValue (value: T);
			
			{ Constructors }			
			constructor Create (values: array of T); overload;
			constructor Create (otherArray: TStaticArray); overload;
			
			{ Introspection }
			function Count: TArrayIndex; inline;
			function High: TArrayIndex; inline;
			
			{ Getting Values }
			function GetValue (index: TArrayIndex): T; inline; overload;
			function GetValue (index: TArrayIndex; out value): boolean; inline; overload;
			
			function GetFirstValue: T;
			function GetLastValue: T;
			function GetAllValues: TValuesArray;
			property Values: TValuesArray read GetAllValues;
			
			function GetIndexOfValue (value: T): TArrayIndex;
			function ContainsValue (value: T): boolean;
			function GetCountOfValues (value: T): integer;
			
			{ Sorting }
			procedure Sort (comparator: TComparator; context: pointer = nil); overload;
			
			{ Methods }
			function GetEnumerator: TArrayEnumerator;
			procedure Show; override;
			
		public
			property ArrayValues[const index:TArrayIndex]:T read GetValue; default;	
		protected
			procedure CopyInstanceVariables (clone: TObject); override;
			procedure Initialize; override;
			procedure Deallocate; override;
									
		private
			ref: TValuesArray;
			weakRetain: boolean;
			typeKind: TTypeKind;
			lastIndex: TArrayIndex;
			
			{ Memory Management }
			procedure RetainValue (value: T); inline;
			procedure ReleaseValue (value: T); inline;
			procedure AutoReleaseValue (value: T); inline;
			
			function CompareValues (a, b: T): boolean; inline;
			function IsDefault (value: T): boolean; inline;
			
			procedure QuickSort (var x: TValuesArray; first, last: LongInt; comparator: TComparator; context: pointer);
			procedure SetAndRetainValue (index: TArrayIndex; value: T);
			procedure PrintValue (value: T);
	end;

type
	generic TDynamicArray<T> = class (specialize TStaticArray<T>)
		public	
					
			{ Memory }
			procedure Reserve (elements: integer);
			procedure Grow (elements: integer);
			
			{ Removing Values }
			procedure RemoveIndex (index: TArrayIndex); virtual; abstract;
			procedure RemoveFirstValue (value: T);
			procedure RemoveAllValues (value: T);
			procedure RemoveValuesFromArray (otherArray: TDynamicArray);
			
			{ Other }
			procedure Swap (src, dest: TArrayIndex);
	end;

type
	generic TGenericArray<T> = class (specialize TDynamicArray<T>)
		public	
			
			{ Pools }
			class procedure Reserve (_count, elements: integer); overload;
			class function DetachFromPool: TGenericArray;
			
			{ Constructors }
			constructor Create (defaultSize: integer); overload;
			constructor Create (_growSize: integer; _shrinks: boolean); overload;
			constructor Instance (_growSize: integer; _shrinks: boolean); overload;
			
			{ Adding Values }
			procedure AddValue (value: T); virtual;
			procedure AddValuesFromArray (otherArray: TGenericArray);
			procedure AddValues (in_values: array of T);
			procedure InsertValue (value: T; index: TArrayIndex);
			procedure InsertValues (in_values: array of T; index: TArrayIndex);
			procedure PrependValue (value: T);
						
			{ Removing Values }
			procedure RemoveIndex (index: TArrayIndex); override;
			procedure RemoveAllValues;
			procedure RemoveValues (index, elements: TArrayIndex);
			
			{ Replacing Values }
			procedure ReplaceValue (index: TArrayIndex; value: T);
			procedure ReplaceValuesFromArray (otherArray: TGenericArray);
			
			{ Space }
			procedure Release; virtual;
			procedure SetGrowSize (newValue: integer); 
			
		protected
			procedure Initialize; override;
			
		private
			growSize: TArrayIndex;
			shrinks: boolean;
			pool: TObject;
			detachedFromPool: boolean;
			
			procedure SetLastIndex (index: TArrayIndex);
	end;

type
	generic TGenericFixedArray<T> = class (specialize TDynamicArray<T>)
		public
		
			{ Constructors }
			constructor Create (size: integer); overload;
			constructor Instance (size: integer); overload;
			
			{ Set Values }
			procedure SetValue (index: TArrayIndex; value: T);
						
			{ Removing Values }
			procedure RemoveIndex (index: TArrayIndex); override;
			procedure Clear;
			
			{ Memory }
			procedure Resize (newSize: TArrayIndex);
	end;

type
	generic TGenericStack<T> = class (specialize TDynamicArray<T>)
		public
			function Pop: T;
			procedure Push (value: T);
		protected
			procedure Initialize; override;
		private
			growSize: integer;
	end;
	TStack = specialize TGenericStack<TObject>;
	
type
	TArray = class (specialize TGenericArray<TObject>)
		public			
			class function ArrayWithValues (args: array of const): TArray;
			procedure AddValue (value: TObject); overload; override;			
	end;
	TArrayComparator = TArray.TComparator;
	TArrayValues = TArray.TValuesArray;
	
type
	TArrayHelper = class helper for TArray
		procedure AddUniqueValue (value: TObject);
		procedure InsertAfter (src, dest: TObject);
		procedure InsertBefore (src, dest: TObject);
	end;

type
	TArrayCommonTypesHelper = class helper(TArrayHelper) for TArray
		procedure AddValue (value: string); overload;
		procedure AddValue (value: boolean); overload;
		procedure AddValue (value: integer); overload;
		
		function GetStringValue (index: TArrayIndex): string;
		function GetIntegerValue (index: TArrayIndex): integer;
		function GetBooleanValue (index: TArrayIndex): boolean;
		function GetFloatValue (index: TArrayIndex): TFloat;
	end;

type
	TArrayJSONHelpers = class helper(TArrayCommonTypesHelper) for TArray
		constructor CreateFromJSON (jsonString: string);
		class function ArrayFromJSON (jsonString: string): TArray;
		function GetJSONString: string;
	end;


{ Fixed Array Types }
type
	TFixedArray = specialize TGenericFixedArray<TObject>;
	TFixedIntegerArray = specialize TGenericFixedArray<Integer>;
	TFixedStringArray = specialize TGenericFixedArray<String>;
	TFixedPointerArray = specialize TGenericFixedArray<Pointer>;
	
{ Dynamic Array Types }
type
	TIntegerArray = specialize TGenericArray<Integer>;
	TLongIntArray = specialize TGenericArray<LongInt>;
	TStringArray = specialize TGenericArray<String>;
	TSingleArray = specialize TGenericArray<Single>;
	TDoubleArray = specialize TGenericArray<Double>;
	TPointerArray = specialize TGenericArray<Pointer>;

type
	TPointArray = specialize TGenericArray<TPoint>;
	TPoint3DArray = specialize TGenericArray<TPoint3D>;
	TRectArray = specialize TGenericArray<TRect>;

var
	ObjectArrayPool: TStack = nil;
	PointerArrayPool: TStack = nil;
	IntegerArrayPool: TStack = nil;
	StringArrayPool: TStack = nil;
	
function TARR: TArray; overload;
function TARR (args: array of const): TArray; overload;

{$macro on}
{$define INTERFACE}

{$define INPUT := TObject}
{$define OUTPUT := TArray}
{$i UArrayOperators.inc}

{$define INPUT := Integer}
{$define OUTPUT := TIntegerArray}
{$i UArrayOperators.inc}

{$define INPUT := Pointer}
{$define OUTPUT := TPointerArray}
{$i UArrayOperators.inc}

{$undef INTERFACE}
{$undef INPUT}
{$undef OUTPUT}

implementation

{=============================================}
{@! ___OPERATORS___ } 
{=============================================}
{$define IMPLEMENTATION}

{$define INPUT := TObject}
{$define OUTPUT := TArray}
{$i UArrayOperators.inc}

{$define INPUT := Integer}
{$define OUTPUT := TIntegerArray}
{$i UArrayOperators.inc}

{$define INPUT := Pointer}
{$define OUTPUT := TPointerArray}
{$i UArrayOperators.inc}

{$undef IMPLEMENTATION}
{$undef INPUT}
{$undef OUTPUT}


{=============================================}
{@! ___COMPARATOR RESULT___ } 
{=============================================}
function TArrayComparatorResultHelper.GreaterThan: boolean;
begin
	result := (self = kArrayComparatorGreaterThan);
end;
function TArrayComparatorResultHelper.LessThan: boolean;
begin
	result := (self = kArrayComparatorLessThan);
end;
function TArrayComparatorResultHelper.GreaterThanOrEqualTo: boolean;
begin
	result := (self = kArrayComparatorGreaterThan) or (self = kArrayComparatorEqualTo);
end;
function TArrayComparatorResultHelper.LessThanOrEqualTo: boolean;
begin
	result := (self = kArrayComparatorLessThan) or (self = kArrayComparatorEqualTo);
end;
function TArrayComparatorResultHelper.EqualTo: boolean;
begin
	result := (self = kArrayComparatorEqualTo);
end;

{=============================================}
{@! ___ARRAY JSON HELPERS___ } 
{=============================================}
constructor TArrayJSONHelpers.CreateFromJSON (jsonString: string);
procedure JSONArrayToTArray (jsonArray: TJSONArray; dest: TArray);
var
	i: integer;
	t: TJSONtype;
	child: TArray;
	num: TNumber;
	str: TString;
begin
	// http://www.freepascal.org/docs-html/3.0.0/fcl/fpjson/tjsonarray.html
	for i := 0 to jsonArray.Count - 1 do
		begin
			t := jsonArray.Types[i];
			case t of
				jtNumber:
					begin
						num := TNumber.Create(jsonArray.Floats[i]);
						dest.AddValue(num);
						num.Release;
					end;
				jtString:
					begin
						str := TString.Create(jsonArray.Strings[i]);
						dest.AddValue(str);
						str.Release;
					end;
				jtBoolean:
					begin
						num := TNumber.Create(jsonArray.Booleans[i]);
						dest.AddValue(num);
						num.Release;
					end;
				jtArray:
					begin
						child := TArray.Create;
						dest.AddValue(child);
						JSONArrayToTArray(jsonArray.Arrays[i], child);
						child.Release;
					end;
				otherwise
					Fatal('unknown json array type '+char(t));
			end;
		end;
end;
var
	arr: TJSONArray;
	i: integer;
	t: TJSONtype;
begin
	Initialize;
	arr := TJSONArray(GetJSON(jsonString));
	if arr = nil then
		raise Exception.Create('String "'+jsonString+'" is invalid JSON.');
	if not arr.InheritsFrom(TJSONArray) then
		raise Exception.Create('String "'+jsonString+'" is not a valid JSON array.');
	JSONArrayToTArray(arr, self);
	arr.Free;
end;

class function TArrayJSONHelpers.ArrayFromJSON (jsonString: string): TArray;
begin
	result := TArray.CreateFromJSON(jsonString);
	result.AutoRelease;
end;

function TArrayJSONHelpers.GetJSONString: string;
var
	arr: TJSONArray;
	value: TObject;
begin
	arr := TJSONArray.Create;
	for pointer(value) in GetAllValues do
		begin
			if value.IsMember(TString) then
				arr.Add(TString(value).GetString)
			else if value.IsMember(TValue) then
				arr.Add(value.GetDescription)
			else
				raise Exception.Create('JSON Value "'+value.ClassName+'" has no string representation.');
		end;
	arr.Free;
end;

{=============================================}
{@! ___ARRAY COMMON TYPES HELPER___ } 
{=============================================}
procedure TArrayCommonTypesHelper.AddValue (value: string);
begin
	AddValue(TSTR(value));
end;

procedure TArrayCommonTypesHelper.AddValue (value: boolean);
begin
	AddValue(TNUM(value));
end;

procedure TArrayCommonTypesHelper.AddValue (value: integer);
begin
	AddValue(TNUM(value));
end;

function TArrayCommonTypesHelper.GetStringValue (index: TArrayIndex): string;
begin
	if GetValue(index).IsMember(TString) then
		result := TString(GetValue(index)).GetString
	else if GetValue(index).IsMember(TNumber) then
		result := IntToStr(GetIntegerValue(index))
	else
		raise Exception.Create('Array value can''t be converted to string.');
end;

function TArrayCommonTypesHelper.GetFloatValue (index: TArrayIndex): TFloat;
begin
	if GetValue(index).IsMember(TNumber) then
		result := TNumber(GetValue(index)).FloatValue
	else if GetValue(index).IsMember(TString) then
		result := StrToFloat(GetStringValue(index))
	else
		raise Exception.Create('Array value be converted to float.');
end;

function TArrayCommonTypesHelper.GetIntegerValue (index: TArrayIndex): integer;
begin
	if GetValue(index).IsMember(TNumber) then
		result := TNumber(GetValue(index)).IntegerValue
	else if GetValue(index).IsMember(TString) then
		result := StrToInt(GetStringValue(index))
	else
		raise Exception.Create('Array value be converted to integer.');
end;

function TArrayCommonTypesHelper.GetBooleanValue (index: TArrayIndex): boolean;
begin
	result := TNumber(GetValue(index)).BooleanValue;
end;

{=============================================}
{@! ___ARRAY HELPER___ } 
{=============================================}
procedure TArrayHelper.AddUniqueValue (value: TObject);
begin
	If not ContainsValue(value) then
		AddValue(value);
end;

procedure TArrayHelper.InsertAfter (src, dest: TObject);
var
	index: integer;
begin
	// ??? is there a better way to do this without resizing the array twice?
	src.Retain;
	RemoveFirstValue(src);
	InsertValue(src, GetIndexOfValue(dest) + 1);
end;

procedure TArrayHelper.InsertBefore (src, dest: TObject);
var
	index: integer;
begin
	// ??? is there a better way to do this without resizing the array twice?
	src.Retain;
	RemoveFirstValue(src);
	InsertValue(src, GetIndexOfValue(dest));
end;

{=============================================}
{@! ___PROCEDURAL___ } 
{=============================================}
function TARR: TArray;
begin
	result := TArray.Instance;
end;

function TARR (args: array of const): TArray;
begin
	result := TArray.ArrayWithValues(args);
end;

// http://www.cquestions.com/2008/01/c-program-for-quick-sort.html
// http://pascal-programming.info/articles/sorting.php

{function BinarySearch (element: TObject; list: TArray; comparator: TArrayComparator; context: pointer): integer;
var
    l, m, h: integer;
begin
	l := 0;
	h := list.Count - 1;
	result := kArrayInvalidIndex;
	while l <= h do
	begin
	    m := (l + h) div 2;
	    //if list[m] > element then
	if comparator(list.GetValue(m), element, context) = kArrayComparatorGreaterThan then
	    begin
	        h := m - 1;
	    end
	    //else if list[m] < element then
	else if comparator(list.GetValue(m), element, context) = kArrayComparatorLessThan then
	    begin
	        l := m + 1;
	    end
	    else
	    begin
	        result := m;
	        break;
	    end;
	end;
end;
}
{=============================================}
{@! ___ENUMERATOR___ } 
{=============================================} 
constructor TStaticArray.TArrayEnumerator.Create(_root: TStaticArray);
begin
	inherited Create;
	root := _root;
end;
	
function TStaticArray.TArrayEnumerator.MoveNext: Boolean;
var
	count: TArrayIndex;
begin
	count := root.Count;
	if index < count then
		currentValue := root.ref[index]
	else
		currentValue := Default(T);
	index += 1;
	result := index <= count;
end;
	
procedure TStaticArray.TArrayEnumerator.Reset;
begin
	index := 0;
end;

{=============================================}
{@! ___GENERIC STACK___ } 
{=============================================}

function TGenericStack.Pop: T;
var
	value: T;
begin
	value := GetLastValue;
	ref[High] := Default(T);
	lastIndex -= 1;
	result := value;
end;

procedure TGenericStack.Push (value: T);
begin
	if lastIndex = Length(ref) then
		Grow(growSize);
	lastIndex += 1;
	SetAndRetainValue(High, value);
end;

procedure TGenericStack.Initialize;
begin
	inherited Initialize;
	
	lastIndex := 0;
	growSize := 8;
end;

{=============================================}
{@! ___GENERIC FIXED ARRAY___ } 
{=============================================}
// Resize array to requested size or shrink last index
// if the requested size is smaller than current size
procedure TGenericFixedArray.Resize (newSize: TArrayIndex);
begin
	if Length(ref) < newSize then
		SetLength(ref, newSize);
	lastIndex := newSize;
end;

procedure TGenericFixedArray.SetValue (index: TArrayIndex; value: T);
begin
//	Fatal(not fixedLength, 'TGenericArray.SetValue: array must be fixed length.');
	Fatal(index >= Count, 'TGenericArray.SetValue: index '+IntToStr(index)+' is out of range ('+IntToStr(Count)+')');
	ReleaseValue(ref[index]);
	ref[index] := value;
	RetainValue(value);
end;

procedure TGenericFixedArray.RemoveIndex (index: TArrayIndex);
begin
	ReleaseValue(ref[index]);
	ref[index] := Default(T);
end;

procedure TGenericFixedArray.Clear;
var
	i: TArrayIndex;
begin
	if Count = 0 then
		exit;
	if weakRetain then
		FillChar(ref[0], Sizeof(T) * Length(ref), 0)
	else
		begin
			for i := 0 to High do
			if ref[i] <> Default(T) then
				begin
					ReleaseValue(ref[i]);
					ref[i] := Default(T);
				end;
		end;
end;

constructor TGenericFixedArray.Create (size: integer);
begin
	SetLength(ref, size);
	lastIndex := size;
	Initialize;
end;

constructor TGenericFixedArray.Instance (size: integer);
begin
	Create(size);
	AutoRelease;
end;

{=============================================}
{@! ___GENERIC ARRAY___ } 
{=============================================}

procedure TGenericArray.ReplaceValuesFromArray (otherArray: TGenericArray);
var
	i: TArrayIndex;
begin
	Reserve(Count + otherArray.Count);
	SetLastIndex(otherArray.Count);
	if weakRetain then
		Move(otherArray.ref[0], ref[0], SizeOf(T) * otherArray.Count)
	else
		begin
			for i := 0 to otherArray.High do
				begin
					ReleaseValue(GetValue(i));
					SetAndRetainValue(i, otherArray.GetValue(i));
				end;
		end;
end;

procedure TGenericArray.ReplaceValue (index: TArrayIndex; value: T);
begin
	ReleaseValue(ref[index]);
	SetAndRetainValue(index, value);
end;

procedure TGenericArray.AddValue (value: T);
begin
	if lastIndex = Length(ref) then
		Grow(growSize);
	SetLastIndex(lastIndex + 1);
	SetAndRetainValue(High, value);
end;

procedure TGenericArray.AddValuesFromArray (otherArray: TGenericArray);
var
	i: TArrayIndex;
	originalLength: TArrayIndex;
	valueCount: TArrayIndex;
begin
	if weakRetain then
		begin
			originalLength := Count;
			valueCount := otherArray.Count;
			Reserve(Count + valueCount);
			Move(otherArray.ref[0], ref[originalLength], SizeOf(T) * valueCount);
			SetLastIndex(lastIndex + valueCount);
		end
	else
		begin
			Reserve(Count + otherArray.Count);
			for i := 0 to otherArray.High do
				begin
					SetAndRetainValue(lastIndex, otherArray.GetValue(i));
					SetLastIndex(lastIndex + 1);
				end;
		end;
end;

procedure TGenericArray.PrependValue (value: T);
begin
	InsertValue(value, 0);
end;

procedure TGenericArray.InsertValue (value: T; index: TArrayIndex);
var
  tail: TArrayIndex;
begin
	if lastIndex = Length(ref) then
		Grow(growSize);
  tail := lastIndex - index;
  if tail > 0 then
    Move(ref[index], ref[index + 1], SizeOf(T) * tail);
  SetAndRetainValue(index, value);
	SetLastIndex(lastIndex + 1);
end;

procedure TGenericArray.InsertValues (in_values: array of T; index: TArrayIndex);
var
	i: TArrayIndex;
begin
  for i := 0 to length(in_values) - 1 do
  	InsertValue(in_values[i], index);
end;

procedure TGenericArray.AddValues (in_values: array of T);
var
	i: TArrayIndex;
begin
	if lastIndex = Length(ref) then
		Grow(Length(in_values));
	for i := 0 to Length(in_values) - 1 do
		AddValue(in_values[i]);
end;

procedure TGenericArray.RemoveValues (index, elements: TArrayIndex);
var
	tail: TArrayIndex;
	i: TArrayIndex;
begin
	if not weakRetain then
	for i := index to index + elements do
		ReleaseValue(ref[i]);
	Move(ref[index + elements], ref[index], SizeOf(T) * elements);
	SetLastIndex(lastIndex - elements);
end;

procedure TGenericArray.RemoveIndex (index: TArrayIndex);
var
	tail: TArrayIndex;
	i: TArrayIndex;
begin
	if index = High then
		begin
			ReleaseValue(ref[index]);
			SetLastIndex(lastIndex - 1);
			exit;
		end;
	ReleaseValue(ref[index]);
	tail := lastIndex - index;
	if tail > 0 then
		begin
			Move(ref[index + 1], ref[index], SizeOf(T) * tail);
			SetLastIndex(lastIndex - 1);
		end;
end;

procedure TGenericArray.RemoveAllValues;
var
	i: TArrayIndex;
begin
	if Count = 0 then
		exit;
	if not weakRetain then
		begin
			for i := 0 to High do
			if not IsDefault(ref[i]) then
				ReleaseValue(ref[i]);
		end;
	SetLastIndex(0);
end;

procedure TGenericArray.Release;
begin
	// clear array and push back the pool if the retain
	// count is decremented to 1
	if detachedFromPool and (GetRetainCount = 1) then
		begin
			//writeln('clear and push back');
			RemoveAllValues;
			TStack(pool).Push(self);
		end;
	inherited Release;
end;

procedure TGenericArray.SetLastIndex (index: TArrayIndex); 
begin
	{
	shrink memory if we add this feature
	}
	lastIndex := index;
end;

procedure TGenericArray.SetGrowSize (newValue: integer); 
begin
	growSize := newValue;
end;

procedure TGenericArray.Initialize; 
begin
	inherited Initialize;
	
	growSize := 16;
	lastIndex := 0;
	shrinks := false;
	detachedFromPool := false;
end;

constructor TGenericArray.Create (defaultSize: integer);
begin
	Initialize;
	Reserve(defaultSize);
end;

constructor TGenericArray.Create (_growSize: integer; _shrinks: boolean);
begin
	growSize := _growSize;
	shrinks := _shrinks;
	Initialize;
end;

constructor TGenericArray.Instance (_growSize: integer; _shrinks: boolean);
begin
	Create(_growSize, _shrinks);
	AutoRelease;
end;

class function TGenericArray.DetachFromPool: TGenericArray;
var
	stack: TStack = nil;
begin
	case PTypeInfo(TypeInfo(T))^.kind of
		tkClass:
			stack := ObjectArrayPool;
		tkPointer:
			stack := PointerArrayPool;
		tkInteger:
			stack := IntegerArrayPool;
		tkString:
			stack := StringArrayPool;
		otherwise
			Fatal('No support for reserving arrays of type.');
	end;
	result := TGenericArray(stack.Pop);
	if result <> nil then
		result.detachedFromPool := true
	else
		result := TGenericArray.Create;
end;

class procedure TGenericArray.Reserve (_count, elements: integer);
var
	arr: TGenericArray;
	stack: TStack = nil;
	i: integer;
begin
	case PTypeInfo(TypeInfo(T))^.kind of
		tkClass:
			stack := ObjectArrayPool;
		tkPointer:
			stack := PointerArrayPool;
		tkInteger:
			stack := IntegerArrayPool;
		tkString:
			stack := StringArrayPool;
		otherwise
			Fatal('No support for reserving arrays of type.');
	end;
	
	for i := 0 to _count - 1 do
		begin
			arr := TGenericArray.Create;
			arr.Reserve(elements);
			// ???SetPool(stack)
			arr.pool := stack;
			stack.Push(arr);
			arr.Release;
		end;
end;

{=============================================}
{@! ___DYNAMIC ARRAY___ } 
{=============================================}

procedure TDynamicArray.Swap (src, dest: TArrayIndex);
var
	tmp: T;
begin
	tmp := ref[dest];
	ref[dest] := ref[src];
	ref[src] := tmp;
end;

// Resize array so it has at least x elements
procedure TDynamicArray.Reserve (elements: integer);
begin
	if Length(ref) < elements then
		SetLength(ref, elements);
end;

// Resize array so it has x more elements
procedure TDynamicArray.Grow (elements: integer);
begin
	SetLength(ref, Length(ref) + elements);
end;

procedure TDynamicArray.RemoveValuesFromArray (otherArray: TDynamicArray);
var
	value: T;
	i: TArrayIndex;
begin
	for value in otherArray do
		begin
			i := GetIndexOfValue(value);
			if i <> kArrayInvalidIndex then
				RemoveIndex(i);
		end;
end;

procedure TDynamicArray.RemoveFirstValue (value: T);
var
	index: TArrayIndex;
begin
	// do nothing with default values
	if IsDefault(value) then
		exit;
	index := GetIndexOfValue(value);
	if index <> kArrayInvalidIndex then
		RemoveIndex(index);
end;

procedure TDynamicArray.RemoveAllValues (value: T);
var
	index: TArrayIndex;
begin
	// do nothing with default values
	if IsDefault(value) then
		exit;
	RetainValue(value);
	index := GetIndexOfValue(value);
	while index <> kArrayInvalidIndex do
		begin
			RemoveIndex(index);
			index := GetIndexOfValue(value);
		end;
	ReleaseValue(value);
end;

{=============================================}
{@! ___STATIC ARRAY___ } 
{=============================================}

function TStaticArray.Count: TArrayIndex;
begin
	if lastIndex = kArrayLiteralSize then
		result := Length(ref)
	else
		result := lastIndex;
end;

function TStaticArray.High: TArrayIndex;
begin
	result := Count - 1;
end;

function TStaticArray.GetFirstValue: T;
begin
	result := GetValue(0);
end;

function TStaticArray.GetAllValues: TValuesArray;
begin
	result := ref;
end;

function TStaticArray.GetLastValue: T;
begin
	result := GetValue(Count - 1);
end;

function TStaticArray.GetValue (index: TArrayIndex; out value): boolean;
var
	_value: T absolute value;
begin
	_value := ref[index];
	result := true;
	exit;
	{if (Count > 0) and (index < Count) then
		begin
			_value := ref[index];
			result := true;
		end
	else
		result := false;}
end;

function TStaticArray.GetValue (index: TArrayIndex): T;
begin
	result := ref[index]
	{if (Count > 0) and (index < Count) then
		result := ref[index]
	else
		result := Default(T);}
end;

procedure TStaticArray.AutoReleaseValue (value: T);
begin
	if weakRetain then
		exit;
	if (typeKind = tkClass) and not IsDefault(value) then
		TObjectPtr(@value)^.AutoRelease;
end;

procedure TStaticArray.RetainValue (value: T);
begin
	if weakRetain then
		exit;
	if (typeKind = tkClass) and not IsDefault(value) then
		TObjectPtr(@value)^.Retain;
end;

procedure TStaticArray.ReleaseValue (value: T);
begin
	if weakRetain then
		exit;
	if (typeKind = tkClass) and not IsDefault(value) then
		TObjectPtr(@value)^.Release;
end;

procedure TStaticArray.SetAndRetainValue (index: TArrayIndex; value: T);
begin
	ref[index] := value;
	RetainValue(value);
end;

function TStaticArray.ContainsValue (value: T): boolean;
begin
	result := GetIndexOfValue(value) <> kArrayInvalidIndex;
end;

function TStaticArray.GetEnumerator: TArrayEnumerator;
begin
	result := TArrayEnumerator.Create(self);
end;

function TStaticArray.GetCountOfValues (value: T): integer;
var
	i: integer;
	theValue: T;
begin
	result := 0;
	for i := 0 to High do
		begin
			theValue := ref[i];
			if CompareValues(theValue, value) then
				result += 1;
		end;
end;

function TStaticArray.GetIndexOfValue (value: T): TArrayIndex;
var
	i: integer;
	theValue: T;
begin
	result := kArrayInvalidIndex;
	for i := 0 to High do
		begin
			theValue := ref[i];
			if not IsDefault(theValue) and CompareValues(theValue, value) then
				exit(i);
		end;
end;

function TStaticArray.CompareValues (a, b: T): boolean;
begin
	if typeKind = tkClass then
		result := TObjectPtr(@a)^.IsEqual(TObjectPtr(@b)^) 
	else
		result := a = b;
end;

function TStaticArray.IsDefault (value: T): boolean;
begin
	result := value = Default(T);
end;

procedure TStaticArray.QuickSort (var x: TValuesArray; first, last: LongInt; comparator: TComparator; context: pointer);
var
	pivot,j,i: integer;
	temp: T;
begin
	if (first < last) then
		begin
			pivot:=first;
      i:=first;
      j:=last;

      while(i<j)do
				begin
					while(comparator(x[i], x[pivot], context).LessThanOrEqualTo and (i<last)) do
						i += 1;
					while(comparator(x[j], x[pivot], context).GreaterThan) do
						j -= 1;
					if i<j then
						begin
							temp:=x[i];
							x[i]:=x[j];
							x[j]:=temp;
						end;
				end;
				
			temp:=x[pivot];
			x[pivot]:=x[j];
			x[j]:=temp;
			QuickSort(x,first,j-1,comparator,context);
			QuickSort(x,j+1,last,comparator,context);
		end;
end;

procedure TStaticArray.Sort (comparator: TComparator; context: pointer = nil);
begin
	QuickSort(ref, 0, Count - 1, comparator, context);
end;

procedure TStaticArray.CopyInstanceVariables (clone: TObject);
var
	source: TStaticArray absolute clone;
	value: T;
	i: TArrayIndex;
begin
	inherited CopyInstanceVariables(clone);
	
	SetLength(ref, source.Count);
	
	if weakRetain then
		Move(source.ref[0], ref[0], Sizeof(T) * Length(ref))
	else
		begin
			for i := 0 to source.High do
				begin
					value := source.GetValue(i);
					//ref[i] := TObjectPtr(@value)^.Copy;
					CopyObject(ref[i], TObjectPtr(@value)^);
				end;
		end;
end;

procedure TStaticArray.PrintValue (value: T);
begin
	case typeKind of
		tkClass:
			begin
				if not IsDefault(value) then
					TObjectPtr(@value)^.Show
				else
					writeln('nil');
			end;
		tkPointer:
			begin
				if not IsDefault(value) then
					writeln(HexStr(PPointer(@value)^))
				else
					writeln('nil');
			end;
		tkRecord:
			writeln('record');
		otherwise
			writeln(PInteger(@value)^); // this is just a hack to print compiler types
	end;
end;

procedure TStaticArray.Show;
var
	i: TArrayIndex;
begin
	writeln('(');
	for i := 0 to High do
		begin
			write(i, ': ');
			PrintValue(ref[i]);
		end;
	writeln(')');
end;

procedure TStaticArray.Deallocate;
var
	i: TArrayIndex;
begin
	if not weakRetain then
	for i := 0 to High do
		ReleaseValue(GetValue(i));
	
	inherited Deallocate;
end;

procedure TStaticArray.Initialize; 
begin
	inherited Initialize;
	
	typeKind := PTypeInfo(TypeInfo(T))^.kind;
	lastIndex := kArrayLiteralSize;
	
	case typeKind of
		tkClass:
			weakRetain := false;
		otherwise
			weakRetain := true;
	end;
end;

constructor TStaticArray.Create (values: array of T);
var
	i: TArrayIndex;
begin
	Initialize;
	SetLength(ref, Length(values));
	lastIndex := kArrayLiteralSize;
	for i := 0 to Length(values) - 1 do
		SetAndRetainValue(i, values[i]);
end;

constructor TStaticArray.Create (otherArray: TStaticArray);
var
	i: TArrayIndex;
begin
	Initialize;
	SetLength(ref, otherArray.Count);
	lastIndex := kArrayLiteralSize;
	for i := 0 to otherArray.High do
		SetAndRetainValue(i, otherArray.GetValue(i));
end;

constructor TStaticArray.ArrayWithArray (otherArray: TStaticArray);
begin
	Create(otherArray);
	AutoRelease;
end;

constructor TStaticArray.ArrayWithValue (value: T);
begin
	Create;
	SetLength(ref, 1);
	lastIndex := kArrayLiteralSize;
	SetAndRetainValue(0, value);
	AutoRelease;
end;

{=============================================}
{@! ___ARRAY___ } 
{=============================================}

// needed for helper classes
procedure TArray.AddValue (value: TObject);
begin
	inherited AddValue(value);
end;

class function TArray.ArrayWithValues (args: array of const): TArray;
var
	i: integer;
	value: TObject;
begin
	result := TArray.Instance;
  for i := 0 to System.high(args) do
		begin
			case args[i].vtype of
	      vtinteger:
					value := TNUM(args[i].vinteger);
			  vtextended:
					value := TNUM(args[i].vextended^);
	      vtboolean:
					value := TNUM(args[i].vboolean);
	      vtchar:
					value := TSTR(args[i].vchar);
	      vtString:
					value := TSTR(args[i].VString^);
	      //vtPointer:
	      //  Writeln (’Pointer, value : ’,Longint(Args[i].VPointer));
	      vtPChar :
					value := TSTR(args[i].VPChar);
	      vtObject:
	      	value := TObject(args[i].VObject);
	      //vtClass      :
	      //  Writeln (’Class reference, name :’,Args[i].VClass.Classname);
	      vtAnsiString:
					value := TSTR(AnsiString(args[i].VAnsiString));
	    	otherwise
	        raise Exception.Create('TArray: variable argument value type '+IntToStr(args[i].vtype)+' is invalid.');
			end;
			result.AddValue(value);
		end;
end;

begin
	ObjectArrayPool := TStack.Create;
	PointerArrayPool := TStack.Create;
	IntegerArrayPool := TStack.Create;
	StringArrayPool := TStack.Create;
	
	RegisterClass(TArray);
end.