Miscellaneous scripts and configuration files for Android
=========================================================

Cross-compiling
---------------
* agcc.pl - revision of Andrew Ross' script updated to work with NDK version r6b.  Preconfigured to build binaries for the NVIDIA Tegra 2.

Keyboard Layouts
----------------
* Vendor_0065_Product_8502.kl - HP Touchpad Wireless Bluetooth Keyboard (US English qwerty layout).

* Vendor_0065_Product_8502_dvorak.kl - Ditto, but for the cool kids (Dvorak layout).

Tested with Honeycomb 3.2 on the Motorola Xoom.  There are currently 3 function keys not working (Virtual Keyboard button and Brightness controls).  The mute button also is not currently muting audio (although it does get recognized by the system).  I'm looking into this.

The upper left key is mapped to Escape as it seems to have the same behaviour as sending "BACK" but with the added benefit of working in vim inside most terminal emulators.
