## A word of caution (or two)
This code is **not** thoroughly tested.

It works for me, but I don't know Xcode's testing tools well enough to set up a sufficiently stable and correct test-rig. (Especially keychain access-groups on iOS boggle my mind — and the pain has not been severe enough to fiddle with everything that *might* have solved the failing tests.)

Furthermore, this code **requires** to be compiled under ARC — i.e. it is iOS 4+ only.

Apart from that, the usual disclaimers apply:

1. **NO WARRANTIES (either implied or explicit) ON ANYTHING.** Regardless if any file contains an express disclaimer or not.
1. If not specified otherwise within the files, this code is covered by a mildly edited form of the [Chicken Dance License](http://supertunaman.com/cdl/cdl_v0-1.txt), which will also be reproduced below in verbatim. (Changes in bold text)

> Copyright (c) 2011, Daniel Demiss
> All rights reserved.
>
> Chicken Dance License v0.1
> http://supertunaman.com/cdl/
>
> Redistribution and use in source and binary forms, with 
> or without modification, are permitted provided that the 
> following conditions are met:
> 
> 1. Redistributions of source code must retain the 
> above copyright notice, this list of conditions and 
> the following disclaimer.
> 2. Redistributions in binary form must reproduce the 
> above copyright notice, this list of conditions and 
> the following disclaimer in the documentation and/or 
> other materials provided with the distribution.
> 3. Neither the name of the CELLULAR GmbH nor the names 
> of its contributors may be used to endorse or promote 
> products derived from this software without specific 
> prior written permission.
> 4. An entity wishing to redistribute in binary form or 
> include this software in their product without 
> redistribution of this software's source code with the 
> product must also submit to these conditions where 
> applicable: 
>   - For every thousand (1000) units distributed, at 
>   least half of the employees or persons 
>   affiliated with the product must listen to the 
>   "Der Ententanz" (AKA "The Chicken Dance") as 
>   composed by Werner Thomas for no less than two 
>   (2) minutes
>    - For every twenty-thousand (20000) units distributed, 
>    two (2) or more persons affiliated with the entity 
>    must be recorded performing the full Chicken Dance, 
>    in an original video at the entity's own expense,
>    and a video encoded in **h.264/AAC** format, at least 
>    three (3) minutes in length, must be submitted to 
>    Daniel Demiss, provided Daniel's contact information. 
>    The dance must be based upon the instructions on 
>    how to do the Chicken Dance that you should have
>    received with this software. If you have not 
>    received instructions on how to do the Chicken
>    Dance, then the dance must be chicken-like in nature.
>    - Any employee or person affiliated with the product 
>    must be prohibited from saying the word "plinth" in 
>    public at all times, as long as distribution of the 
>    product continues. 
> 
> THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
> "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
> LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
> FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
> COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
> INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
> BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
> LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
> CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
> LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
> ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
> POSSIBILITY OF SUCH DAMAGE. CELLULAR GmbH ACCEPTS NO LIABILITY FOR
> ANY INJURIES OR EXPENSES SUSTAINED IN THE ACT OF FULFILLING ANY OF 
> THE ABOVE TERMS AND CONDITIONS, ACCIDENTAL OR OTHERWISE.
