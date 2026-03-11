# Educational project "residentRegisters"  
## Description  
A resident program that, when a key 'F11' is pressed, displays a frame with the current values ​​of registers and flags, updated with each timer tick.
<img width="1024" height="639" alt="image" src="https://github.com/user-attachments/assets/3619f4e4-1f07-4fba-ad15-1c3a2529eebc" />

## Features  

-The frame appears on the screen when the key 'F11' is pressed and disappears when the key 'F12' is pressed.  

-The current register and flag values ​​are updated every timer tick.  

-The values ​​of registers and flags that were changed after the frame appeared are colored white.  

-Saves and keeps the background under the frame up to date.

-The frame has a shadow that matches the background.

<img width="1026" height="646" alt="image" src="https://github.com/user-attachments/assets/2ac79f26-af6d-4a2e-97a9-3c60c0ca3340" />


## Realization  

-The program replaces the segment and offset of еру 09 interrupt in the interrupt table with the segment and offset of my function,
which monitors the F11 and F12 key presses to display and remove the frame.

