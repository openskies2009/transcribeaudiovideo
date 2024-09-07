# Audio/Video Transcription with Whisper and FFmpeg
Bash Script: MP3 to Text Conversion with Whisper


This Bash script automates the process of transcribing audio and video files using OpenAI's Whisper model. It supports various audio/video formats, converts non-MP3 files to MP3 using FFmpeg, and generates subtitles in .srt format.

Features:

Input Directory: Prompts the user to specify the folder containing audio/video files.

Output Directory: Prompts the user to specify the folder where the transcriptions will be saved.

Supported Formats: Automatically processes files with extensions .mp4, .wav, .flac, .mp3, .amr, and .m4a.

File Conversion: Converts non-MP3 files (e.g., .mp4, .wav) to temporary MP3 files using FFmpeg.

Whisper Integration: Runs Whisper for transcription with English language support and outputs .srt subtitle files.

Multithreading: Utilizes up to 4 threads for faster processing.

Automatic Directory Creation: Creates the output directory if it doesn’t already exist.

Prerequisites:

FFmpeg: Ensure FFmpeg is installed for audio conversion.

Whisper: Install the Whisper model via Whisper GitHub.

Usage:

Clone the repository or copy the script.

Ensure FFmpeg and Whisper are installed.

Run the script and provide the input/output directories as prompted.
