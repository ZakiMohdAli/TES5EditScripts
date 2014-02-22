{
  matortheeternal's Functions
  A set of useful functions for use in TES5Edit scripts.
  
  **LIST OF INCLUDED FUNCTIONS**
  - [ReverseString]: reverses a string.
  - [ItPos]: finds the position of an iteration of a substring in a string.
  - [CopyFromTo]: copies all characters in a string from a starting position to an 
    ending position.
  - [GroupSignature]: gets the signature of a group record.
  - [HexFormID]: gets the FormID of a record as a hexadecimal string.
  - [ElementByIP]: loads an element by an indexed path.
  - [geev]: GetElementEditValues enhanced with ElementByIP.
  - [genv]: GetElementNativeValues enhanced with ElementByIP.
  - [seev]: SetElementEditValues enhanced with ElementByIP.
  - [senv]: SetElementNativeValues enhanced with ElementByIP.
  - [SetListEditValues]: Sets the edit values in a list of elements to the values 
    stored in a stringlist.
  - [SetListNativeValues]: Sets the native values in a list of elements to the values
    stored in a TList.
  - [FileSelect]: Creates a window from which the user can select or create a file.
    Doesn't include bethesda master files.
}

unit mteFunctions;

{
  ReverseString:
  Reverses a string.
  
  This function will allow you to quickly reverse a string.
  
  Example usage:
  s := 'backwards';
  S := ReverseString(s);
  AddMessage(s); // 'sdrawkcab'
}
function ReverseString(s: string): string;
var
  i: integer;
begin
   Result := '';
   for i := Length(s) downto 1 do begin
     Result := Result + Copy(s, i, 1);
   end;
end;

{ 
  ItPos:
  An iteration position function.
  
  This function will allow you to find the position of a substring in a
  string, or the position of the second, third, etc. iterations of that
  substring.  If the iteration of the substring isn't found -1 is returned.
  
  Example usage:
  s := '10101';
  k := ItPos(s, '1', 3);
  AddMessage(IntToStr(k)); // 5
}
function ItPos(str: string, substr: string, it: integer): integer;
var
  i, found: integer;
begin
  Result := -1;
  if it = 0 then exit;
  found := 0;
  for i := 1 to Length(str) do begin
    if SameText(Copy(str, i, Length(substr)), substr) then Inc(found);
    if found = it then Result := i;
  end;
end;

{
  CopyFromTo:
  A copy function that allows you to copy from one position to another.
  
  This function is a better copy function, in my opinion.
  
  Example usage:
  s := 'Hi.  I'm a cool guy.';
  s := CopyFromTo(s, Pos('a', s), Pos('g', s));
  AddMessage(s); //'a cool g'
}
function CopyFromTo(s: string; p1: integer; p2: integer): string;
var
  i: integer;
begin
  Result := '';
  for i := 1 to Length(s) do begin
    if i >= p1 then Result := Result + Copy(s, i, 1);
    if i = p2 then exit;
  end;
end;

{
  GroupSignature:
  Gets the signature of a group record.
  
  This is useful if you want to get a list of the groups in a file.
  
  Example usage:
  s := GroupSignature(GroupBySignature(f, 'COBJ'));
  AddMessage(s); //'COBJ'
}
function GroupSignature(g: IInterface): string;
var
  s: string;
  ct: integer;
begin
  s := Name(g);
  ct := Length(s) - Length(Copy(s, 1, Pos('"', s))) - 1; 
  Result := Copy(s, Pos('"', s) + 1, ct);
end;

{
  HexFormID
  Gets the formID of a record as a hexadecimal string.
  
  This is useful for just about every time you want to deal with FormIDs.
  
  Example usage:
  s := HexFormID(e);
}
function HexFormID(e: IInterface): string;
var
  s: string;
begin
  s := GetElementEditValues(e, 'Record Header\FormID');
  if SameText(Signature(e), '') then 
    Result := '00000000'
  else  
    Result := Copy(s, Pos('[' + Signature(e) + ':', s) + Length(Signature(e)) + 2, 8);
end;
  
{
  ElementByIP:
  Element by Indexed Path
  
  This is a function to help with getting at elements that are inside 
  lists.  It allows you to use an "indexed path" to get at these elements
  that would otherwise be inaccessible without multiple lines of code.
  
  Example usage:
  element0 := ElementByIP(e, 'Conditions\[0]\CTDA - \Function');
  element1 := ElementByIP(e, 'Conditions\[1]\CTDA - \Function');
}
function ElementByIP(e: IInterface; ip: string): IInterface;
var
  subpath: string;
  i, index: integer;
  subelement: IInterface;
begin
  ip := StringReplace(ip, '/', '\', [rfReplaceAll]);
  subelement := e;
  While (Pos('[', ip) > 0) do begin
    subpath := CopyFromTo(ip, 1, Pos('\', ip) - 1);
    if Pos('[', subpath) > 0 then begin 
      index := StrToInt(CopyFromTo(subpath, Pos('[', ip) + 1, Pos(']', ip) - 1));
      subelement := ElementByIndex(subelement, index);
    end
    else
      subelement := ElementByPath(subelement, subpath);
    if Pos('\', ip) > 0 then
      ip := CopyFromTo(ip, Pos('\', ip) + 1, Length(ip))
    else
      ip := '';
  end;
  if not SameText(ip, '') then 
    Result := ElementByPath(subelement, ip)
  else
    Result := subelement;
end;

{
  geev:
  GetElementEditValues, enhanced with ElementByIP.
  
  Example usage:
  s1 := geev(e, 'Conditions\[3]\CTDA - \Function');
  s2 := geev(e, 'KWDA\[2]');
}
function geev(e: IInterface; ip: string): string;
begin
  Result := GetEditValue(ElementByIP(e, ip));
end;

{
  genv:
  GetElementNativeValues, enhanced with ElementByIP.
  
  Example usage:
  f1 := genv(e, 'KWDA\[3]');
  f2 := genv(e, 'Armature\[2]');
}
function genv(e: IInterface; ip: string): variant;
begin
  Result := GetNativeValue(ElementByIP(e, ip));
end;

{
  seev:
  SetElementEditValues, enhanced with ElementByIP.
  
  Example usage:
  seev(e, 'Conditions\[2]\CTDA - \Type', '10000000');
  seev(e, 'KWDA\[0]'),
}
procedure seev(e: IInterface; ip: string; val: string);
begin
  SetEditValue(ElementByIP(e, ip), val);
end;

{
  senv:
  SetElementNativeValues, enhanced with ElementByIP.
  
  Example usage:
  senv(e, 'KWDA\[1]', $0006C0EE); // $0006C0EE is ArmorHelmet keyword
}
procedure senv(e: IInterface; ip: string; val: variant);
begin
  SetNativeValue(ElementByIP(e, ip), val);
end;

{
  SetListEditValues:
  Sets the values of elements in a list to values stored in a stringlist.
  
  Example usage:
  SetListEditValues(e, 'Additional Races', slAdditionalRaces);
}
procedure SetListEditValues(e: IInterface; ip: string; values: TStringList);
var
  i: integer;
  list, newelement: IInterface;
begin
  // exit if values is empty
  if values.Count = 0 then exit;
  
  list := ElementByIP(e, ip);
  // clear element list except for one element
  While ElementCount(list) > 1 do
    RemoveByIndex(list, 0);
  
  // set element[0] to values[0]
  SetEditValue(ElementByIndex(list, 0), values[0]);
  // create elements for the rest of the list
  for i := 1 to values.Count - 1 do begin
    newelement := ElementAssign(list, HighInteger, nil, False);
    SetEditValue(newelement, values[i]);
  end;
end;

{
  SetListNativeValues:
  Sets the native values of elements in a list to the values stored in a Tlist.
  
  Example usage:
  SetListNativeValues(e, 'KWDA', lstKeywords);
}
procedure SetListNativeValues(e: IInterface; ip: string; values: TList);
var
  i: integer;
  list, newelement: IInterface;
begin
  // exit if values is empty
  if values.Count = 0 then exit;
  
  list := ElementByIP(e, ip);
  // clear element list except for one element
  While ElementCount(list) > 1 do
    RemoveByIndex(list, 0);
  
  // set element[0] to values[0]
  SetNativeValue(ElementByIndex(list, 0), values[0]);
  // create elements for the rest of the list
  for i := 1 to values.Count - 1 do begin
    newelement := ElementAssign(list, HighInteger, nil, False);
    SetNativeValue(newelement, values[i]);
  end;
end;

{
  FileSelect:
  Creates a form for the user to select a file to be used.
  
  Example usage:
  UserFile := FileSelect('Select the file you wish to use below: ');
}
function FileSelect(prompt: string): IInterface;
var
  frm: TForm;
  lbl: TLabel;
  cbFiles: TComboBox;
  btnOk, btnCancel: TButton;
  i: integer;
  s: string;
begin
  frm := TForm.Create(nil);
  try
    frm.Caption := 'Select File';
    frm.Width := 300;
    frm.Height := 170;
    frm.Position := poScreenCenter;
    
    lbl := TLabel.Create(frm);
    lbl.Parent := frm;
    lbl.Width := 284;
    if Pos(#13, prompt) > 0 then begin
      lbl.Height := 60;
    end
    else begin
      lbl.Height := 30;
      frm.Height := 160;
    end;
    lbl.Left := 8;
    lbl.Top := 8;
    lbl.Caption := prompt;
    lbl.Autosize := false;
    lbl.Wordwrap := True;
    
    cbFiles := TComboBox.Create(frm);
    cbFiles.Parent := frm;
    cbFiles.Items.Add('-- CREATE NEW FILE --');
    cbFiles.Top := lbl.Top + lbl.Height + 20;
    cbFiles.Left := 8;
    cbFiles.Width := 200;
    for i := 0 to FileCount - 1 do begin
      s := GetFileName(FileByIndex(i));
      if SameText(s, 'Skyrim.esm') or SameText(s, 'Dawnguard.esm') or SameText(s, 'Dragonborn.esm') or SameText(s, 'Hearthfires.esm')
      or SameText(s, 'Update.esm') or SameText(s, 'Skyrim.Hardcoded.keep.this.with.the.exe.and.otherwise.ignore.it.I.really.mean.it.dat') then Continue;
      cbFiles.Items.Add(s);
    end;
    cbFiles.ItemIndex := 0;
    
    btnOk := TButton.Create(frm);
    btnOk.Parent := frm;
    btnOk.Left := 150 - btnOk.Width - 8;
    btnOk.Top := cbFiles.Top + 40;
    btnOk.Caption := 'OK';
    btnOk.ModalResult := mrOk;
    
    btnCancel := TButton.Create(frm);
    btnCancel.Parent := frm;
    btnCancel.Caption := 'Cancel';
    btnCancel.ModalResult := mrCancel;
    btnCancel.Left := btnOk.Left + btnOk.Width + 16;
    btnCancel.Top := btnOk.Top;
    
    if frm.ShowModal = mrOk then begin
      if SameText(cbFiles.Items[cbFiles.ItemIndex], '-- CREATE NEW FILE --') then Result := AddNewFile
      else begin
        for i := 0 to FileCount - 1 do begin
          if SameText(cbFiles.Items[cbFiles.ItemIndex], GetFileName(FileByIndex(i))) then begin
            Result := FileByIndex(i);
            Continue;
          end;
          if i = FileCount - 1 then begin
            AddMessage('The script couldn''t find the file you entered.');
            Result := FileSelect(prompt);
          end;
        end;
      end;
    end;
  finally
    frm.Free;
  end;
end;

end.