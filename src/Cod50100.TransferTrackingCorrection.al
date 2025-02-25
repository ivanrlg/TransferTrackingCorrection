codeunit 50100 TransferTrackingCorrection
{
    procedure CorrectTransferTrackings(TransferNo: Code[20])
    var
        TransferLine: Record "Transfer Line";
        RegisteredPick: Record "Registered Whse. Activity Line";
        ReservationEntry: Record "Reservation Entry";
        Window: Dialog;
        ConfirmQst: Label 'Are you sure you want to correct the tracking lines for Transfer %1?';
        Progress: Label 'Processing serials...';
        LastEntryNo: Integer;
        NoTrackingFoundErr: Label 'No missing tracking lines were found for this transfer line.';
        ProcessCompletedMsg: Label 'Tracking lines correction process completed successfully.';
        TrackingFoundCount: Integer;
        ExistingSerials: List of [Code[50]];
    begin
        // Validate transfer line exists
        TransferLine.Reset();
        TransferLine.SetRange("Document No.", TransferNo);

        if not TransferLine.FindFirst() then
            Error('Transfer Line %1-%2 not found.', TransferNo);

        if not Confirm(ConfirmQst, false, TransferNo) then
            exit;

        Window.Open(Progress);

        // Initialize counter
        TrackingFoundCount := 0;

        // Get existing surplus serials first
        ExistingSerials := GetExistingSurplusSerials(TransferLine);

        // Find registered picks related to this transfer line
        RegisteredPick.Reset();
        RegisteredPick.SetRange("Source Type", Database::"Transfer Line");
        RegisteredPick.SetRange("Source No.", TransferLine."Document No.");
        RegisteredPick.SetRange("Activity Type", RegisteredPick."Activity Type"::Pick);
        RegisteredPick.SetRange("Action Type", RegisteredPick."Action Type"::Take);

        if RegisteredPick.FindSet() then begin
            repeat
                // Only process serials that aren't already in surplus and have a serial number
                if (RegisteredPick."Serial No." <> '') and (not ExistingSerials.Contains(RegisteredPick."Serial No.")) then begin
                    // Get last Entry No from Reservation Entry
                    ReservationEntry.Reset();
                    if ReservationEntry.FindLast() then
                        LastEntryNo := ReservationEntry."Entry No." + 1
                    else
                        LastEntryNo := 1;

                    // Create the surplus entry using information from the Registered Pick
                    CreateSurplusReservationEntry(
                        LastEntryNo,
                        TransferLine,
                        RegisteredPick
                    );

                    TrackingFoundCount += 1;
                end;
            until RegisteredPick.Next() = 0;
        end;

        Window.Close();

        if TrackingFoundCount = 0 then
            Message(NoTrackingFoundErr)
        else
            Message(ProcessCompletedMsg + '\\' +
                   'Number of tracking lines corrected: %1', TrackingFoundCount);
    end;

    local procedure GetExistingSurplusSerials(TransferLine: Record "Transfer Line") SerialList: List of [Code[50]]
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.Reset();
        ReservationEntry.SetRange("Source Type", Database::"Transfer Line");
        ReservationEntry.SetRange("Source ID", TransferLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", TransferLine."Line No.");
        ReservationEntry.SetRange("Item No.", TransferLine."Item No.");
        ReservationEntry.SetRange("Variant Code", TransferLine."Variant Code");
        ReservationEntry.SetRange("Location Code", TransferLine."Transfer-from Code");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange(Positive, true);

        if ReservationEntry.FindSet() then
            repeat
                if not SerialList.Contains(ReservationEntry."Serial No.") then
                    SerialList.Add(ReservationEntry."Serial No.");
            until ReservationEntry.Next() = 0;
    end;

    local procedure CreateSurplusReservationEntry(
    EntryNo: Integer;
    TransferLine: Record "Transfer Line";
    RegisteredPick: Record "Registered Whse. Activity Line")
    var
        ReservationEntry: Record "Reservation Entry";
        TransferShipmentLine: Record "Transfer Shipment Line";
        SourceRefNo: Integer;
    begin
        // Find related Transfer Shipment Line to get correct Source Ref. No.
        TransferShipmentLine.Reset();
        TransferShipmentLine.SetRange("Transfer Order No.", TransferLine."Document No.");
        TransferShipmentLine.SetRange("Item No.", RegisteredPick."Item No.");
        TransferShipmentLine.SetRange("Variant Code", RegisteredPick."Variant Code");
        TransferShipmentLine.SetRange("Trans. Order Line No.", RegisteredPick."Source Line No.");

        SourceRefNo := 0;

        if TransferShipmentLine.FindSet() then
            repeat
                if TransferShipmentLine.Quantity > 0 then
                    SourceRefNo := TransferShipmentLine."Derived Trans. Order Line No."
            until TransferShipmentLine.Next() = 0
        else
            Error('Transfer Shipment Line not found for Transfer Line %1-%2.', TransferLine."Document No.", TransferLine."Line No.");

        // Create surplus reservation entry (positive)
        Clear(ReservationEntry);
        ReservationEntry.Init();
        ReservationEntry."Entry No." := EntryNo;
        ReservationEntry."Source Type" := Database::"Transfer Line";
        ReservationEntry."Source Subtype" := 1;
        ReservationEntry."Source ID" := TransferLine."Document No.";
        ReservationEntry."Source Ref. No." := SourceRefNo;
        ReservationEntry."Item No." := RegisteredPick."Item No.";
        ReservationEntry."Variant Code" := RegisteredPick."Variant Code";
        ReservationEntry."Serial No." := RegisteredPick."Serial No.";
        ReservationEntry."Location Code" := TransferLine."Transfer-to Code";
        ReservationEntry.Positive := true;
        ReservationEntry."Quantity (Base)" := 1;  // Always 1 for serialized items
        ReservationEntry.Quantity := 1;          // Always 1 for serialized items
        ReservationEntry."Qty. to Handle (Base)" := 1;
        ReservationEntry."Qty. to Invoice (Base)" := 1;
        ReservationEntry."Shipment Date" := TransferLine."Shipment Date";
        ReservationEntry."Expected Receipt Date" := TransferLine."Receipt Date";
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Surplus;
        ReservationEntry."Creation Date" := Today;
        ReservationEntry."Source Prod. Order Line" := RegisteredPick."Source Line No.";  // Set to Transfer Line No.
        ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Serial No.";
        ReservationEntry.Insert();
    end;
}