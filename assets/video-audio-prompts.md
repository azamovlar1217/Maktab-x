# MAKTAB X video and music generation prompts

The prompts below are production briefs for an image-to-video or text-to-video tool. They are not generated media files. Use the generated `school-hero.png`, `student-boy.png`, `student-girl.png`, and `x-robot.png` as visual references where the tool supports reference images.

## Landing page hero loop

**Prompt (English tends to preserve visual directions more reliably):**

> Create a polished 8-second seamless looping 3D animated hero background for MAKTAB X, a modern Uzbek school learning platform. Match the supplied blue-and-white reference images: preserve the same friendly glossy white robot with blue accents and X chest mark, plus the same two school students in blue school clothing. Scene: bright contemporary school courtyard in soft morning light. The robot gives a small friendly wave; the students exchange a happy glance and open a book; a few subtle blue light particles drift gently. Camera locked, very slow gentle push-in that returns exactly to the opening framing. Keep character design, wardrobe, faces, scale, and school architecture consistent across every frame. Leave the left 40 percent low-detail and open for HTML headline/buttons. Premium soft 3D animation, restrained motion, calm, trustworthy, age appropriate, no flashing, no fast cuts. Make the final frame match the first frame for a clean continuous loop. 16:9, 1920×1080. No soundtrack, no voice, no captions, no readable text, no logos other than the simple X badge, no watermark.

**Integration:** save as `assets/video/maktab-x-home-loop.mp4` (H.264, no audio track, 16:9). In the landing hero, use `<video muted autoplay loop playsinline>` with a static poster fallback. Keep all headline and buttons as HTML. Respect `prefers-reduced-motion` by showing the poster instead of playing the loop. Never autoplay sound.

## Robot greeting clip

> Use the supplied MAKTAB X robot image as the exact character reference. Create a 6-second transparent-background 3D animation: friendly white-and-blue school robot looks at camera, raises one hand, waves twice, blinks its cyan eyes, then returns to its original neutral pose. Fixed camera, consistent body geometry and colors, smooth natural motion, clean alpha background, no camera shake, no extra objects, no text, no speech, no music, no watermark. The beginning and end poses should match for looping. 1:1, 1024×1024.

**Integration:** use as a short muted looping illustration beside AI Ustoz or in the welcome card, with the static robot PNG as fallback.

## Original background music

> Compose an original 45-second instrumental identity bed for MAKTAB X, an uplifting but calm educational product for Uzbek school students, teachers, and families. Warm piano motif, light marimba, soft plucked strings, subtle hand percussion, gentle airy pads; optimistic, curious, modern, trustworthy, and focused. Medium-slow 92 BPM, major tonality, no dramatic build or drop, no recognizable existing melody, no imitation of any artist, no vocal, no spoken words. Keep transients soft so narration can sit above it. End with a musically natural loop point that can connect cleanly to the opening. Stereo, 48 kHz, deliver a full mix and a 10-second seamless menu loop.

**Integration:** save the supplied approved recording as `assets/audio/maktab-x-music.mp3`. Do not autoplay audio. Add a clearly labeled play/pause and volume control only in the introduction-video player; the landing page loop remains silent.

## Uzbek narration direction

> Record an original, friendly Uzbek-language voiceover in clear Latin-script Uzbek pronunciation, warm and encouraging, at a relaxed pace. Do not imitate a real person or clone a voice. Keep room tone low and leave pauses between sentences. Deliver a dry voice track with no music, 48 kHz WAV, plus a transcript and captions (`.vtt`). The approved script will be supplied separately; do not invent names, school claims, prices, partnerships, or statistics.
