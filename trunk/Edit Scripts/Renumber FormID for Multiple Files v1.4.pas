{
  Renumber FormID for Multiple Files Script
  Created by matortheeternal
  http://skyrim.nexusmods.com/mod/37981

  *CHANGES*
  v1.4
    - The script now uses Int64 variables to store formIDs, so overflow errors
      with mods at load order exceeding 80 should no longer occur.
  
  *DESCRIPTION*
  This script will allow you to renumber the FormIDs in multiple files in one go.
  This is particularly useful before merging plugins, as it will avoid FormID
  conflicts which you might otherwise encounter.  The v1.4 merging script will
  renumber FormIDs for you, but this script is still included in case you want to
  do things out of order or something like that.  User variables can be set at
  line 37.
}

unit userscript;
var
  manymessages, manualrenumber: boolean;
  slRenumber: TStringList;
  
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
 
function Initialize: integer;
begin
  // set user variables
  // --------------------------------------------------------------------------
 
  // set this to false to print fewer messages to the message log
  manymessages := false;
  // set this to true to manually enter the starting formID to renumber from
  manualrenumber := false;
 
  // --------------------------------------------------------------------------
  // end user variables
 
  // welcome messages
  AddMessage(#13#10#13#10#13#10);
  AddMessage('-----------------------------------------------------------------------------');
  AddMessage('Renumber FormID for Multiple Files script');
  AddMessage('-----------------------------------------------------------------------------');
  // end welcome messages
 
  // stringlist creation
  slRenumber := TStringList.Create;
  // done creating stringlists
  
  // process only file elements
  ScriptProcessElements := [etFile];
  
end;

// recognize the selected files for renumbering
function Process(f: IInterface): integer;
var
  i: integer;
  masters, e: IInterface;
  ismaster: Boolean;
  s: string;
begin
  if (ElementType(f) = etMainRecord) then Exit;
  s := GetFileName(f);

  // skip masters which shouldn't be renumbered under any conditions
  if SameText(s, 'Skyrim.esm') or
     SameText(s, 'Skyrim.exe') or
     SameText(s, 'Update.esm') or
     SameText(s, 'Dawnguard.esm') or
     SameText(s, 'Dragonborn.esm') 
  then
    Exit;
    
  slRenumber.AddObject(s, TObject(GetLoadOrder(f)));
  
end;
 
// renumbering the stuff
function Finalize: integer;
var
  i, j, RC: integer;
  f, e: IInterface;
  s: string;
  HighestFormID, OldFormID, NewFormID, BaseFormID: Int64;
  self: boolean;
  Records: array [0..$FFFFFF] of IInterface;
begin
  // terminate script if the renumbering list contains no files
  if slRenumber.Count < 1 then begin
    AddMessage(#13#10+'Select at least 1 file to renumber the FormIDs in!  Terminating script.');
    slRenumber.Free;
    Exit;
  end;
  
    // renumber forms in files to be merged
  AddMessage(#13#10+'Renumbering FormIDs...');
  HighestFormID := 0;
  NewFormID := 0;
  BaseFormID := 0;
  
  // find the ideal NewFormID to start at
  for i := 0 to slRenumber.Count - 1 do begin
    f := FileByLoadOrder(Integer(slRenumber.Objects[i]));
    for j := 0 to RecordCount(f) - 1 do begin
      e := RecordByIndex(f, j);
      if not Equals(e, MasterOrSelf(e)) then Continue;
      s := Copy(HexFormID(e), 3, 6);
      if StrToInt64('$' + s) > HighestFormID then HighestFormID := StrToInt64('$' + s);
    end;
  end;
  
  // form id renumbering for each file
  for i := 0 to slRenumber.Count - 1 do begin
    f := FileByLoadOrder(Integer(slRenumber.Objects[i]));
    RC := RecordCount(f) - 1;
    AddMessage('    Renumbering records in file '+GetFileName(f));
    
    // create records array for file because the indexed order of records changes as we alter their formIDs
    for j := 0 to RC do
      Records[j] := RecordByIndex(f, j);
    
    // initialize NewFormID based on HighestFormID found
    if manualrenumber and (BaseFormID = 0) then begin
      s := InputBox('Enter', 'New starting FormID', IntToHex64(HighestFormID + 4096, 8));
      BaseFormID := StrToInt64('$' + s);
    end
    else begin
      BaseFormID := HighestFormID + 4096;
    end;
    // set newformID to use the load order of the file currently being processed.
    NewFormID := StrToInt64('$' + IntToHex(Integer(slRenumber.Objects[i]), 2) + IntToHex(BaseFormID, 6));
      
    // renumber the records in the file
    for j := 0 to RC do begin
      e := Records[j];
      if SameText(Signature(e), 'TES4') then Continue;
      
      // set up form id junk
      OldFormID := StrToInt64('$' + HexFormID(e));
      
      // continue if formIDs are identical or if record is override
      if NewFormID = OldFormID then Continue;
      self := Equals(MasterOrSelf(e), e);
      if not self then begin
        if manymessages then AddMessage('        Skipping '+Name(e)+', it''s an override record.');
        Continue;
      end;
      
      // print log message first, then change references, then change form
      if manymessages then 
        AddMessage(Format('        Changing FormID from [%s] to [%s] on %s', [IntToHex64(OldFormID, 8), IntToHex64(NewFormID, 8), Name(e)]));
      while ReferencedByCount(e) > 0 do
        CompareExchangeFormID(ReferencedByIndex(e, 0), OldFormID, NewFormID);
      SetLoadOrderFormID(e, NewFormID);
      
      // increment formid
      Inc(BaseFormID);
      Inc(NewFormID);
      
    end;
  end;

  // script is done, print confirmation messages
  AddMessage(#13#10);
  AddMessage('-----------------------------------------------------------------------------');
  AddMessage('Renumbering completed.  Make sure you exit TES5Edit saving your changes before merging!');
  AddMessage('Also, make sure you have Backup plugins checked in the save window!  If renumbering breaks the original files you can restore the backups.');
  AddMessage(#13#10#13#10);
  
  // clean stringlists
  slRenumber.Free;
  Result := -1;
  
end;


end.
