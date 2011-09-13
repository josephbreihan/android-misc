Miscellaneous scripts and configuration files for Android
=========================================================

Cross-compiling
---------------
* agcc.pl - revision of Andrew Ross' script updated to work with NDK version r6b.  Preconfigured to build binaries for the NVIDIA Tegra 2.

Keyboard Layouts
----------------
US English QWERTY:

* Vendor_0065_Product_8502.kl - HP Touchpad Wireless Bluetooth Keyboard

Dvorak:

* Vendor_0065_Product_8502_dvorak.kl - HP Touchpad Wireless Bluetooth Keyboard
* Vendor_05ac_Product_0239_dvorak.kl - Apple Wireless Bluetooth Keyboard
* Vendor_22b8_Product_093d_dvorak.kl - Motorola Xoom Bluetooth Keyboard

The HP Touchpad Wireless Bluetooth keyboard layouts have been tested with Honeycomb 3.2 on the Motorola Xoom.  There are currently 3 function keys not working (Virtual Keyboard button and Brightness controls).  The mute button also is not currently muting audio (although it does get recognized by the system).  I'm looking into this.

In these keylayout files, I've mapped the he upper left key to "Escape" as it seems to have the same behaviour as sending "Back" but with the added benefit of working in vi inside most terminal emulators.
