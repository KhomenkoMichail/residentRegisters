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

-The program replaces the segment and offset of the 09 interrupt in the interrupt table with the segment and offset of my function "registersDebugger09Int",
which monitors key presses, compares them with'F11' and 'F12' scan-codes and displays and removes the frame if they match.  

-The program replaces the segment and offset of the 09 interrupt in the interrupt table with the segment and offset of my function "printfRegs08Int",
which draws a frame with updated flag and register values ​​every timer tick.  

-The initial values ​​of the registers and flags are saved in the corresponding buffers. Each timer tick, they are compared with the current values.
If they don't match, the attributes of their symbols in video memory are set to white.  

-The program implements triple buffering. When you press 'F11', the background under the frame is saved to the "Save" buffer on page 6 of video memory.
Each timer tick, the frame is drawn to the "Draw" buffer on the 5th video memory page and then copied from there to the screen. 
Before this, the frame in the "Draw" buffer is compared with the frame on the screen. If differences are detected, the frame from the screen is copied to the "Save" buffer.
This keeps the "Save" buffer up-to-date. When you press 'F12', the "Save" buffer is copied to the screen, preserving the correct background.  

-The frame shadow is also created using triple buffering. It is placed into the "Save" buffer along with the frame. 
In the "Draw" buffer, it is redrawn, taking into account the symbol attributes, which are replaced with those with a black background and dimmed symbols. Each timer tick, the shadow is also checked for relevance and updated in the "Save" buffer.
