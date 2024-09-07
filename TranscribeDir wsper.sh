#!/bin/bash

# Prompt the user for the input directory
read -p "Please enter the directory where your audio/video files are located: " input_dir

# Prompt the user for the output directory
read -p "Please enter the directory where you want the Whisper output to be saved: " output_dir



# Check if the input directory exists
if [ ! -d "$input_dir" ]; then
    echo "Input directory does not exist. Exiting..."
    exit 1
fi

# Check if the output directory exists, if not, create it
if [ ! -d "$output_dir" ]; then
    echo "Output directory does not exist. Creating it..."
    mkdir -p "$output_dir"
fi

# Search for audio/video files in the provided directory
find "$input_dir" -type f \( -iname "*.mp4" -o -iname "*.wav" -o -iname "*.flac" -o -iname "*.mp3" -o -iname "*.amr" -o -iname "*.m4a" \) | while read -r file; do
    # Check if the file is already an MP3

Echo "PROCESSING"+ $file;

    if [[ "$file" != *.mp3 ]]; then
        # Create a temporary MP3 file
        temp_mp3="ragtemp.mp3"

Echo "CONVERTING"+ $file;
Echo "TEMP MP3"+ $temp_mp3;

        # Convert to MP3 using ffmpeg
        ffmpeg -i "$file" -q:a 0 -map a "$temp_mp3"

        # Pass the temporary MP3 file to whisper
        whisper "$temp_mp3"  --language English   --output_format srt --threads 4 --output_dir "$output_dir"

        # Remove the temporary MP3 file after whisper is done
        rm -f "$temp_mp3"
    else
        # If already an MP3, use it directly
        whisper "$file" --language English   --output_format srt  --threads 4 --output_dir "$output_dir"
    fi
done
