# BC-Transfer-Tracking-Correction

## Overview
This repository contains the source code for a specialized Business Central solution that automatically fixes corrupted serial number tracking in transfer orders. When serial information gets lost during the transfer process, this tool reconstructs the necessary reservation entries, saving hours of manual correction work.

## Features
- Automatically rebuilds missing serial tracking information in transfer receipts
- Uses registered pick data as the source of truth for serial numbers
- Creates proper surplus reservation entries in the destination location
- Works seamlessly with standard Business Central processes

## Components
- Codeunit "Transfer Tracking Correction": Main orchestrator that handles the tracking recovery process
- Local procedure "GetExistingSurplusSerials": Identifies which serials already have correct entries
- Local procedure "CreateSurplusReservationEntry": Creates the critical surplus entries with proper references

## Usage
To fix serial tracking issues in a transfer order:
1. Navigate to the affected transfer order
2. Run the "Correct Transfer Trackings" action
3. Confirm the operation when prompted
4. Check the Item Tracking Lines to verify the serials have been restored

## When to Use
This utility is most helpful when:
- Users encounter "You must assign a serial number" errors when posting receipts
- Item tracking lines are missing in the receipt part of transfer orders
- Serial numbers exist in the shipment but are missing in the receipt
- Manual correction would be too time-consuming or error-prone

## Implementation
Simply add this codeunit to your Business Central environment and create an action on the transfer order page that calls the `CorrectTransferTrackings` procedure.

## License
This project is available under the MIT License - see the LICENSE.md file for details.

## Learn More
For a comprehensive explanation of how this solution works and the technical details behind it, please refer to my detailed blog post on [Fixing Serial Number Tracking in Business Central Transfer Orders]([[https://ivansingleton.dev/fixing-serial-number-tracking-business-central-transfer-order](https://ivansingleton.dev/how-to-instantly-fix-broken-serial-tracking-in-bc-transfer-orders/)s/](https://ivansingleton.dev/how-to-instantly-fix-broken-serial-tracking-in-bc-transfer-orders/)).

## Additional Notes
While uncommon, serial tracking issues can be extremely frustrating when they occur. This solution demonstrates how to effectively rebuild reservation entries by understanding the critical relationships between Business Central's transfer document tables. The approach could potentially be extended to other scenarios where reservation entries need repair.
