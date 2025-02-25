pageextension 50100 "Tranfer Order MSCE" extends "Transfer Order"
{
    actions
    {
        addafter("Get Bin Content")
        {
            action(FixReservationWrong)
            {
                ApplicationArea = All;
                Caption = 'Transfer Tracking Correction';
                Visible = true;
                Image = Track;
                ToolTip = 'Corrects missing tracking lines by recreating them from registered picks.';

                trigger OnAction()
                var
                    TrackingCorr: Codeunit "TransferTrackingCorrection";
                begin
                    TrackingCorr.CorrectTransferTrackings(Rec."No.");
                end;
            }
        }
    }
}
