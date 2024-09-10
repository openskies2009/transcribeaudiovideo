#!/bin/bash

reffereceword ='scene number'

printf "\n\n\nTranscribeDir Written by Peter Friedlander: peterfriedlander.tv
Running this will transcribe any audio or video files found in the input directory using Whisper from OpenAI and append the spoken content. It will also automatically translate any foreign languages spoken. %s\n" 
printf "\n\n"
# Prompt the user for the input directory
read -p "Please enter the directory where your audio/video files are located: " input_dir

# Display Output format
printf "\n\n"
echo "Select output file type:"
echo "1) Transcription"
echo "2) Subtitle File with Timestamps"
echo "3) Burn Transcriptions (Creates smaller copies of videos with subtitles burnt in, also with srt files."
read -p "Enter the number corresponding to the output file: " file_choice


# Display model type options and prompt user for selection
printf "\n\n"
echo "Select model type:"
echo "1) Fast"
echo "2) Accurate (better to catch scene numbers)"
read -p "Enter the number corresponding to the model type: " model_choice

# Determine the whisper model based on user choice
case "$model_choice" in
    1)
        whisper_model="tiny"
        ;;
    2)
        whisper_model="large"
        ;;
    *)
        echo "Invalid option. Please select '1' for Fast or '2' for Accurate."
        exit 1
        ;;
esac

# Determine the whisper output file based on user choice
case "$file_choice" in
    1)
        whisper_output="txt"
        ;;
    2)
        whisper_output="srt"
        ;;
    3)
        whisper_output="srt"
        subburn="1";
        ;;

    *)
        echo "Invalid option. Please select '1' for Fast or '2' for File Output."
        exit 1
        ;;
esac

# Check if the input directory exists
if [ ! -d "$input_dir" ]; then
    echo "Input directory does not exist. Exiting..."
    exit 1
fi

# Prompt the user whether to process the scene number in .srt files
printf "\n\n"
read -p "Do you want to rename files based on the spoken markers? (Creates srt files only) ? (y/N): " process_scenes
process_scenes=$(echo "$process_scenes" | tr '[:upper:]' '[:lower:]') # Convert to lowercase


if [ "$process_scenes" == "y" ]; then
whisper_output="srt"

# Prompt the user for input
read -p "Enter a sentence (leave blank to keep the current phrase 'scene number'. Appends the first occurrence of the spoken phrase to the srt filename in the audio track.  ): " user_refference_word

Echo "user_refference_word=$user_refference_word"

# Only update the sentence if input is provided
if [[ -n "$user_refference_word" ]]; then
    reffereceword="$user_refference_word"
fi
# Output the final sentence
echo "The sentence is: $reffereceword"
fi


process_srt() {
    srt_file="$1"
    
    # Find the last occurrence of the reference word and extract the following text
    scene_info=$(awk -v ref="$reffereceword" '
    BEGIN { 
        ref = tolower(ref)
    }
    {
        if (tolower($0) ~ ref) {
            last_line = $0
        }
    }
    END {
        if (length(last_line) > 0) {
            # Find the position of the reference word
            idx = match(tolower(last_line), ref)
            if (idx > 0) {
                # Extract the text following the reference word
                following_text = substr(last_line, idx + length(ref))
                split(following_text, words, " ")
                result = ""
                for (i = 1; i <= 3 && i <= length(words); i++) {
                    result = result (length(result) > 0 ? " " : "") words[i]
                }
                print result
            }
        }
    }' "$srt_file")

    if [ -n "$scene_info" ]; then
        # Remove leading and trailing whitespace
        scene_info=$(echo "$scene_info" | xargs)
        # Create a new filename with the extracted info
        new_filename="${srt_file%.srt} - ${scene_info}.srt"
        # Ensure the new filename does not exist already
        if [ ! -e "$new_filename" ]; then
            mv "$srt_file" "$new_filename"
            echo "Renamed '$srt_file' to '$new_filename'"
        else
            echo "File '$new_filename' already exists. Skipping rename."
        fi
    else
        echo "No occurrence of '$reffereceword' found in '$srt_file'"
    fi
}



# Temporary file to track processed .srt files
processed_srt_files=$(mktemp)

# Function to process audio/video files
process_files() {
    local dir="$1"
    
    # Find and process audio/video files
    find "$dir" -type f \( -iname "*.mp4" -o -iname "*.wav"  -o -iname "*.mpg"  -o -iname "*.WAV" -o -iname "*.flac" -o -iname "*.mov" -o -iname "*.mp3" -o -iname "*.amr" -o -iname "*.m4a" \) | while read -r file; do
        echo "PROCESSING $file"

        if [[ "$file" != *.mp3 ]]; then
            base_filename=$(basename "$file" | sed 's/\.[^.]*$//')
            output_dir=$(dirname "$file")
            temp_mp3="$output_dir/$base_filename.mp3"

            echo "CONVERTING $file"
            echo "TEMP MP3 $temp_mp3"

            # Convert to MP3 using ffmpeg
            ffmpeg -i "$file" -q:a 0 -map a "$temp_mp3"

            # Pass the temporary MP3 file to whisper
            whisper "$temp_mp3" --language English --model "$whisper_model" --output_format "$whisper_output" --output_dir "$output_dir"

            # Remove the temporary MP3 file after whisper is done
            rm -f "$temp_mp3"
        else
            output_dir=$(dirname "$file")
            whisper "$file" --language English --model "$whisper_model" --output_format "$whisper_output" --output_dir "$output_dir"
        fi



#STARITNG BURN IN SECTION
Echo "sunburn is $subburn"

if [ "$subburn" == "1" ]; then

Echo "BURING IN SUBS IN $file"
Echo "base is $base_filename"
if [[ $(ffprobe -v error -select_streams v:0 -show_entries stream=codec_type -of csv=p=0 "$file" 2>/dev/null) == "video" ]]; then

#start burning in video subs 
# Assign arguments to variables
video_file="$file"
subtitle_file="$output_dir/$base_filename.srt"

# Output file (adding '_with_subs' to the original filename)
output_file="${video_file%.*}_with_subs.${video_file##*.}"
# Check if video file exists
if [ ! -f "$video_file" ]; then
    echo "Error: Video file '$video_file' not found."
    exit 1
fi

# Check if subtitle file exists
if [ ! -f "$subtitle_file" ]; then
    echo "Error: Subtitle file '$subtitle_file' not found."
    exit 1
fi

# Burn subtitles into the video using ffmpeg
ffmpeg -i "$video_file" -vf "subtitles=$subtitle_file,scale=1280:-1" -b:v 1M -c:a copy "$output_file"


# Check if ffmpeg command was successful
if [ $? -eq 0 ]; then
    echo "Subtitles burned successfully! Output file: $output_file"
else
    echo "Error burning subtitles into the video."
    exit 1
fi


else
    echo "$file is not a video file"
fi


#end burning subs in video 
fi
#ENDING BURN IN SECTION


#DONE LookingOPING directories
    done

}


# Function to process .srt files
process_srt_files() {
    local dir="$1"

    find "$dir" -type f -iname "*.srt" | while read -r srt_file; do
        if ! grep -Fxq "$srt_file" "$processed_srt_files"; then
            process_srt "$srt_file"
            echo "$srt_file" >> "$processed_srt_files"
        fi
    done
}

# Start processing
process_files "$input_dir"

# Only process .srt files if the user agreed
if [ "$process_scenes" == "y" ]; then
    process_srt_files "$input_dir"
else
    echo "Skipping .srt file processing."
fi

# Clean up temporary file
rm -f "$processed_srt_files"
