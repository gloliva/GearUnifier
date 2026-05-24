# Gear Unifier for Modular Systems (GUMS)

## Application Overview

**Gear Unifier for Modular Systems (GUMS)** is a node-based interactive software system that aids in the composition and performance with physical hardware. GUMS allows the user to easily connect and control hardware of different protocols, whether MIDI, serial, or control voltage (CV). The GUMS software is extremely configurable for a variety of hardware and software configurations. An example use case might be to connect 1) a custom MIDI controller that sends CC values over Bluetooth, 2) a traditional MIDI keyboard that supports polyphonic aftertouch, and 3) a Eurorack modular synthesizer for a live performance. In this setup, the user may want to modulate the FM parameters of a Eurorack oscillator module using the custom MIDI controller, and control the pitch of this oscillator with the MIDI keyboard. This is simply achieved by adding two MIDI In nodes to the patch, which correspond to their respective MIDI devices, selecting the appropriate outputs (CC data for the first MIDI node, pitch, gate, and aftertouch data for the second MIDI node), and connecting the outputs to the Audio Out node, which will be configured to be the Eurorack's audio interface module.

## Table of Contents

- [Why GUMS Over Other Software?](#why-gums-over-other-software)
- [Why the name GUMS?](#why-the-name-gums)
- [How to Run](#how-to-run)
- [Nodes and Connections](#nodes-and-connections)
- [Components of a Node](#components-of-a-node)
  - [Name Section](#name-section)
  - [Options Section](#options-section)
  - [Inputs Section](#inputs-section)
  - [Outputs Section](#outputs-section)
  - [Buttons Section](#buttons-section)
  - [Visibility Section](#visibility-section)
- [Navigating the UI](#navigating-the-ui)
- [Sequencing](#sequencing)
  - [MIDI Sequencing](#midi-sequencing)
  - [Composer System](#composer-system)
  - [Composer Notation](#composer-notation)

---

## Why GUMS Over Other Software?

GUMS was designed to be in the middle of programs like Max/MSP and VCV Rack in terms of ease-of-use and depth of customization. Providing high level abstractions for device management and sequencing, this allows the user to get started making music faster compared to programming languages (Max/MSP, ChucK, supercollider, etc.). On the flip side, GUMS provides enough flexibility and configuration through custom scripting should they want to go deeper than what a DAW or programs like VCV Rack provide.


## Why the name GUMS?

Naming projects is difficult. I came up with the name Gear Unifier for Modular Systems early in the development process, and although I spent a lot of time trying to think of a catchier name, this one stuck. *Modular Systems* in this context does not just refer to modular synthesizers, but to any setup that involves many individual components, such as custom serial devices, networked computers, MIDI keyboards, analog synths, digital software, etc. The purpose of this software is to act as the central hub between those devices, giving complete control to the user in how they communicate with each other (i.e., *unifying* them).

GUMS, while being a silly acronym, is like "gum", a sticky substance used to bind objects together (e.g., your gear). Yes, this is all a bit of stretch to justify a bad name.


## How to Run

GUMS is written in the ChucK programming language. You will need to have [ChucK installed](https://chuck.stanford.edu/release/) in order to run GUMS. To install the necessary dependencies, run the script `./scripts/install`.

If there are any issues with the installation script or running the program, the required libraries can be installed manually via the following:

```
chump install HashMap
chump install
chump install smuck
cp ./chugins/UUID.chug /usr/local/lib/chuck/
```

You will need to select the audio device to use for your inputs and outputs. To determine what audio devices are available to ChucK, you can run the following: `chuck --probe`. Example output might look like:

```
> chuck —probe
[chuck]: [CoreAudio] driver found 7 audio device(s)...
[chuck]:
[chuck]: ------( audio device: 1 )------
[chuck]: device name = "Apple Inc.: iPhone 13 Microphone"
[chuck]: probe [success]...
[chuck]: # output channels = 0
[chuck]: # input channels  = 1
[chuck]: # duplex Channels = 0
[chuck]: default output = NO
[chuck]: default input = NO
[chuck]: natively supported data formats:
[chuck]:   32-bit float
[chuck]: supported sample rates:
[chuck]:   48000 Hz

[chuck]: ------( audio device: 2 )------
[chuck]: device name = "Existential Audio Inc.: BlackHole 16ch"
[chuck]: probe [success]...
[chuck]: # output channels = 16
[chuck]: # input channels  = 16
[chuck]: # duplex Channels = 16
[chuck]: default output = NO
[chuck]: default input = NO
[chuck]: natively supported data formats:
[chuck]:   32-bit float
[chuck]: supported sample rates:
[chuck]:   44100 Hz
[chuck]:   48000 Hz

[chuck]: ------( audio device: 3 )------
[chuck]: device name = "Existential Audio Inc.: BlackHole 64ch"
[chuck]: probe [success]...
[chuck]: # output channels = 64
[chuck]: # input channels  = 64
[chuck]: # duplex Channels = 64
[chuck]: default output = NO
[chuck]: default input = NO
[chuck]: natively supported data formats:
[chuck]:   32-bit float
[chuck]: supported sample rates:
[chuck]:   44100 Hz
[chuck]:   48000 Hz
…
```

To run the software, run the following command:

```
chuck --adc:<INPUT_DEVICE_ID> --in:<NUMBER_OF_INPUT_CHANNELS> --dac:<OUTPUT_DEVICE_ID> --out:<NUMBER_OF_OUTPUT_CHANNELS> --srate:<SAMPLE_RATE> main.ck
```

For example, using the above `chuck --probe` output, if you want to use BlackHole 16ch as your input audio device and BlackHole 64ch as your output audio device, you would run:

```
chuck --adc:2 --dac:3 main.ck
```

To explicitly select the number of input channels to be 8, and number of output channels to be 16, you can run:

```
chuck --adc:2 --in:8 --dac:3 --out:16 main.ck
```

Finally, if you want to explicitly set the sample rate to 48000, the full command would be:

```
chuck --adc:2 --in:8 --dac:3 --out:16 --srate:48000 main.ck
```

## Nodes and Connections

GUMS is a node-based visual configuration language, similar to languages like Max/MSP and TouchDesigner. The user will add nodes to the screen, which can represent a variety of objects, such as MIDI devices, sequencers, effects, live coding environments, data visualization tools, and more.

All nodes have inputs, outputs, or both. Inputs and outputs both have a text block that describes the IO parameter as well as an IO jack where connections are made. Some inputs and outputs are fixed and cannot be changed. For example, the ADSR node has 1 input, the Gate signal that triggers the envelope, and 1 output, the envelope waveform. Other nodes support customizable inputs and outputs. For example, the MIDI In node has 4 inputs and 8 outputs. You may only need a subset of these parameters, such as the Tuning input to change the default tuning of 12 EDO into another scale, and the Pitch, Gate, and Aftertouch outputs. By clicking on the text block next to the IO jack, a dropdown menu will appear, allowing you to select which parameter should be assigned to that input or output. Typically, a node that supports configurable inputs or outputs will also have "-" and "+" buttons above the IO section; this allows you to remove or add inputs/outputs. For example, the MIDI In node defaults to 1 input and 3 outputs. If you would like to include a second input, you would click on the "+" button above the inputs section. To only use 1 output, you would click on the "-" button above the outputs section twice.

Clicking on a node's output jack will start a connection. A red wire will appear at the output jack and will follow your mouse cursor. Clicking on another node's input jack will then complete the connection and the wire's color will change to black. Data being sent from the output node's output will then be processed by the input node in accordance to what output and input parameter are selected. Making these connections in GUMS is identical to how they function in other Node-based languages, and is like connecting one Eurorack module to another.

Most outputs are sent as a "signal", which is a continuous stream of numbers. Whether this signal is processed at audio rate (sample by sample) or control rate is dependent upon both the output type and how the input node processes the incoming data. The goal is that this distinction for different inputs/outputs is typically "what you would expect" and happens "automagically".

For inputs that toggle or trigger something, a value greater than 0. is considered HIGH (or "on") and a value of less than or equal to 0. is considered LOW (or "off"). For example, the MIDI In node has a "Latch" input. Sending in a HIGH signal to this input will enable Latch (meaning MIDI Note Off messages will be ignored). Sending a LOW signal will turn Latch off.

## Components of a Node

A typical node is made up of several sections, which are described below. Most nodes do not contain every section, but a node will typically have at least an inputs or an outputs section.

### Name Section

The name section is the top section of the node and displays the node's name. Some nodes simply display what they are, for example an ADSR envelope node will display "ADSR". Other nodes, like MIDI In nodes, will display the MIDI device name, such as "Lumatone" or "Novation LaunchPad".

### Options Section

Many nodes have an Options section, which contains parameters that are typically changed only once, as opposed to parameters that can be changed dynamically via a node's inputs. For example, the Transport node has a PPQN option, which sets the "Pulses Per Quarter Note" that adjusts the Transport's clock out output. This is typically a parameter that you would set just once to sync with external hardware and not need to change over the course of a performance.

Some parameters have the ability to both change via the options section and via inputs. The Transport node allows you to set the Tempo directly from the options section, if you intend to only set it once. However, it can also be dynamically changed via the "Tempo In" input jack if you would like to adjust the tempo via external means, such as from a MIDI CC message.

Some options are changed via a dropdown menu, such as selecting the MIDI channel on a MIDI In node. Other options are changed by text entry. For example, when clicking on the Tempo value of the Transport node, you can press "Delete" / "Backspace" to delete a character, numeric characters to enter values, and a period character "." to enter a float value. Pressing "Enter" or clicking away will set the new value as the option value.

### Inputs Section

Some nodes have an inputs section, which is used to dynamically set node parameters and for chaining nodes together. For example, a MIDI In node has 4 inputs: "Sequencer" for connecting a MIDI sequencer, "Latch" which will toggle the Latch mode off / on, "Transport" to connect a transport node for changing the MIDI arpeggiation tempo, and "Tuning" to change the tuning scale of the node's output pitch values. When a connection has been started, clicking on a node's input jack will complete the connection, and the data from the output node will flow into the input node.

Some nodes have a fixed number of inputs, but other nodes support configurable inputs. If the latter, a node's input section will have two buttons, a "-" and a "+", directly above the inputs section. Clicking on "-" will remove an input (and delete the connection, if there is one), and clicking on "+" will add a new input.

### Outputs Section

Some nodes have an outputs section, which is used to send data from one node to another via a connection. The outputs section functions very similarly to the inputs section in that some nodes have fixed outputs and others can be configured. An output jack can be clicked on to begin a connection.

### Buttons Section

Some nodes have a Button section, which is a series of buttons, that when clicked, toggle some functionality that is specific to that particular node. For example, the "Composer" node has buttons that opens up a "Composer Text Box" window. The particular button functionality is described within the individual node's documentation section.

### Visibility Section

Most nodes have a Visibility section, which is the very last section of the node. The Visibility section allows you to hide sections of a node that you might not currently need. The Visibility section is tailored to each node, but most nodes have three buttons, "Opts" corresponding to the Options section, "Ins" for the Inputs section, and "Outs" for the outputs. Clicking on this button will cause the entire section to be hidden and the node's size to be condensed. To show the section, click on the corresponding button again. Hiding a node's inputs or outputs section will not remove or disable the connections, they will still continue to function as you would expect.

## Navigating the UI

The GUMS UI is fairly simple to use. The top bar contains the categories of nodes that can be added to the current patch. Clicking on one of these categories opens a dropdown menu with the different nodes that belong to that category. For example, clicking on the "Effects" category shows the nodes "Wavefolder", "Distortion", and "Delay". Clicking on a node in this dropdown menu will add it to the middle of the screen.

Nodes can be selected by clicking on the node's "Name" section. This is the top portion of the node that displays the node's name. Clicking on the node's name will turn the color of the name bar from black to red, showing that it is currently selected. To move this node around, click on the name of the node, and while holding the mouse button down, drag the node to the position you want it to be in. To delete a node, press the "Delete" / "Backspace" key on your keyboard while the node is selected.

The bottom bar contains the buttons for Saving and Loading patches. These buttons function as you would expect: the "Save As" button will always open a File Dialog window that allows you to enter the name and location of the saved patch. If the patch has not previously been saved, the "Save" button will act as the "Save As" button, otherwise it will save to the current filename. The "Load" button will open a File Dialog window that allows you to select a previously saved patch. The "New" button will clear the screen, removing all connections and nodes. **WARNING**: when a File Dialog window is opened, the software will pause, which will halt all audio and graphics processing until the window is closed. Thus, it is advised to not open this window via Save/Load in the middle of a performance.

Vertical mouse scrolling will scroll the screen up / down. Zoom into a patch with `cmd`-`+` and zoom out with `cmd`-`-`.

## Sequencing

There are currently two ways to sequence in GUMS: 1) recording and playback of MIDI notes via a MIDI In node and 2) a fully customizable composition language for defining arbitrary sequences, rhythms, and envelopes. The former method is the easiest way to get started if using a MIDI keyboard, the second method allows for composing sequences and having dynamic control of the playback during a performance environment.

### MIDI Sequencing

If you have a MIDI keyboard / have a device that sends MIDI messages, those MIDI messages can be recorded and played back dynamically. This is done with the MIDI Sequencer node, which is found under the "Sequencing" node category. To record MIDI input with a MIDI Sequencer, connect the "Seq Out" output from the MIDI Sequencer to the "Sequencer" input of the MIDI In node.

The MIDI Sequencer has two inputs, a "Run" input and a "Record" input. When the "Record" input receives a signal value greater than 0., it will begin to record all MIDI messages that correspond to the connected MIDI In device. Any MIDI message, including CC messages and aftertouch values, will be recorded. When the signal value is 0. or below, the recording will be stopped.

To playback the recorded MIDI sequence, connect a signal to the "Run" input of the MIDI sequencer. When the "Run" input goes HIGH, the MIDI messages will be played back in the exact order that they were recorded.

There are many ways to send signals to the "Record" and "Run" inputs, including MIDI Gate messages, MIDI CC messages, and Eurorack CV. One common way is to send a Gate signal into a Toggle node, with the Toggle output connected to the "Record" or "Run" input of the MIDI Sequencer node.

### Composer System

The composer system is a comprehensive sequencing system that supports composition and playback of complex, arbitrary sequences.

Under the hood, the composer system utilizes "smuck", which is a framework for writing music in ChucK with symbolic music notation. smuck is an extremely flexible way to compose music in ChucK; however, it still requires "writing code". The composer system is a wrapper on top of smuck that allows for simpler composition through a text-based notation system and the GUMS graphical interface.

There are two nodes that make up the Composer system: the Composer and ScorePlayer. The composer node can be thought of as a single voice (or part, using smuck terminology), and lets the user define sequences of notes. There are four parts to the structure of a composer node: 1) The Score, which is composed of 2) Scenes, which are made up of 3) Sequences, which contain 4) Notes. A note defines pitch information (either as MIDI or as a frequency), rhythm information (using smuck syntax, or as a fixed ChucK duration), and envelope information (standard ADSR as well as customizable envelope curves). A sequence is similar to either a "phrase" or "measure", and contains one or more notes. Sequences are composed using a custom notation language, which is described in further detail below. Multiple sequences, played in a particular order, make up a Scene, which can be thought of as a "section" or "movement". Scenes, by default, will play in chronological order, but the user has control to play them in any particular order, either dynamically during a performance or through a pre-determined ordering. Finally, all of the scenes defined by the user make up the Score, which can be thought of as the completed "piece".

The ScorePlayer node, like its name suggests, is used to play and set parameters regarding the entire score defined by a Composer node. This includes score playback (playing, pausing, looping, and restarting a score), changing the tempo of a score, and changing the rate of a score (similar to tempo, but with subtle differences — for example, rate can be a negative value to play the piece in reverse). A single ScorePlayer node can be connected to multiple Composer nodes to control them simultaneously.

Additional nodes that can be used within the Composer System framework are the Transport node and the Tuning nodes (EDOTuning and ScaleTuning), which can be used to control the score's overall tempo and set the tunings used for a specific voice, respectively.

### Composer Notation

A scene, and the sequences contained therein, are written using a custom notation language. A sequence is defined between "less than" and "greater than" symbols, i.e. `<` and `>`.

```
# This is a single sequence defined in a Scene
<
  # Sequence 1 data goes here
>


# Multiple sequences defined in a Scene
<
  # Sequence 1
> <
  # Sequence 2
> <
  # Sequence 3
>
```

Note data is defined within the brackets of a sequence. Each line contains information pertaining to a single note, such as the pitch, the note length, and the envelope information. The order of defining this information is as follows:

```
<
  ScaleDegree RhythmValue OctaveRegister EnvelopeData
>
```

By default, a Composer node uses the 12 Equal Temperament scale. The ScaleDegree would then be a value from 0 (indicating the first degree of the scale, the tonic) and 11 (the 12th degree of the scale, the leading tone). A value greater than the scale degree will bring it into the next octave (e.g. 12 will be one octave higher, 19 will be a perfect 5th one octave higher). A negative value will move into the below octave (-2 will play the 10th scale degree of the octave below). The scale can be changed away from 12TET by connecting an EDOTuning or ScaleTuning node to the Composer node. For example, if the scale is set to the pentatonic minor scale, 0 will be the first scale degree, 4 will be the last scale degree, and 5 will be the first scale degree, one octave higher. To specify a rest note, the letter "r" should be used instead of an integer.

Rhythm information can be given in two forms: 1) smuck style rhythm notation (e.g. "s" for sixteenth note, "e" for eighth note, "q" for quarter, etc.) or as a fixed duration (i.e. 250::ms, 3::second, 800::sample, 4::minute, etc.). For a complete list of smuck rhythm notations, see [this documentation page](https://chuck.stanford.edu/smuck/doc/smuckish.html#rhythm).

Octave values start with the letter "o" and are followed by the register number. "o2" is the second register, "o5" is the fifth register, and so on.

Envelope information can be specified in several ways, but takes the form `<envelope_type>( <ramp_length> <envelope_value> )`. Envelope type can be "a", "d", "r", and "e", corresponding to Attack (triggers at note start), Decay (triggers after Attack), Release (triggers after the note is released), and Envelope (a generic envelope ramp that can be used for enveloping outside of typical ASR and ADSR patterns). Ramp length is the time it takes to reach the envelope value, and takes the form of [ChucK timing syntax](https://chuck.stanford.edu/doc/language/time.html). The envelope value is a float and typically represents volume.

A three beat sequence might look like the following:

```
<
  0 q o4 a(25::ms 0.8) r(500::ms 0.)
  7 q o4 a(25::ms 0.6) r(500::ms 0.)
  r e
  3 e o4 a(25::ms 0.7) r(250::ms 0.)
>
```

The above example uses an ASR (Attack, Sustain, and Release) envelope style. ADSR envelopes can be created with the following syntax:

```
<
  0 q 04 a(100::ms 0.6) d(300::ms 0.5) r(1500::ms 0.)
  r h.
>
```

Generic enveloping can be used in combination with traditional ADSR values:

```
<
  0 h 04 a(500::ms 0.5) d(200::ms 0.8) e(1000::ms 0.2)
  0 q 04 e(125::ms 0.4) e(250::ms 0.2) r(250::ms 0.)
  r q
>
```

When a sequence is started with `<`, prior to any note information, the user can define some metadata, such as the name of the sequence and how many times it repeats. Naming a sequence allows the user to recall it later on. The Loop parameter will repeat the sequence that many times before moving onto the next sequence. Both of these are optional.

```
<
  ! name mySequenceName
  ! loop 4
>
```

To recall a named sequence in the same scene, use the "!" symbol followed by the sequence's name:

```
<
  # defining our first sequence
  ! name seqOne
  ! loop 4
  # sequence data ...
> <
  # defining a second sequence
  ! name seqTwo
  ! loop 2
  # sequence data ...
> <
  # Reuse sequence one here, with a different number of repeats
  ! seqOne
  ! loop 2
>
```

A complete scene, containing three unique sequences, might look like this:

```
<
  ! name seq1
  ! loop 16
    7 e o5 a(25::ms 0.6) d(e 0.3) r(250::ms 0.)
    5 e o6 a(25::ms 0.6) d(e 0.3) r(250::ms 0.)
    0 s o6 a(25::ms 0.6) d(e 0.3) r(250::ms 0.)
    5 s o5 a(25::ms 0.6) d(e 0.3) r(250::ms 0.)
> <
  ! name seq2
  ! loop 8
    0 e o5 a(25::ms 0.6) d(e 0.3) r(250::ms 0.)
    10 e o5 a(25::ms 0.6) d(e 0.3) r(250::ms 0.)
    3 s o6 a(25::ms 0.6) d(e 0.3) r(250::ms 0.)
    3 s o5 a(25::ms 0.6) d(e 0.3) r(250::ms 0.)
> <
  ! seq1
  ! loop 4
> <
  ! seq2
  ! loop 4
> <
  ! name seq3
  ! loop 8
    0 e o5 a(25::ms 0.6) d(e 0.3) r(250::ms 0.)
    r e
    3 s o6 a(25::ms 0.6) d(e 0.3) r(250::ms 0.)
    3 s o5 a(25::ms 0.6) d(e 0.3) r(250::ms 0.)
>
```
