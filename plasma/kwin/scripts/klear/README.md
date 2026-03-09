# Klear

**New in 0.2.1: customize your opacity level**
Sadly, this requires a full system restart after adjusting. The KWin API has been undergoing many changes, and the `changeConfig()` feature for `options` is not behaving as expected. For this reason, I think we're going to take future development over to the widgets section. Should we keep hitting dead ends like this, we'll likely stop developing for Plasma altogether until there are reliable APIs to work with. That's not me being a bitch to KDE, but rather acknowledging that they need some time to wrap up the qt6 adjustments.


## Description
Very primitive KWin script for KDE Plasma 6.2, which makes regular desktop windows 75% transparent on opening. I've been stoked with the reliability of Plasma since the 6.1 release, but am still having some graphics issues. So why not roll my own!?


Requirements :
- KDE Plasma 6.2 (likely anything from 6.0)
- A shitty enough graphics card to bother downloading

How to install :

1. Open System Settings -> Window Management -> KWin Scripts
2. Click on "Get New..."
3. Search for Klear
4. Install from the GUI
5. Enable the script by clicking on the checkbox next to it
6. Click Apply.
7. **Click on the settings button for the Klear script.** Adjust your preferred opacity. Lowest setting is 40%, highest is 100%.
8. Sadly, a full restart is required after changing the opacity. See the initial description above for details.

How to use it :

1. Once you've enabled the script in the steps above, all "normal" desktop windows you open will be transparent at the setting you specified.