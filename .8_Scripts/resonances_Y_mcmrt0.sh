#!/bin/bash

# Get the current time and date
time_str=$(date +"%H%M")
date_str=$(date +"%d%m%Y")

# Construct the output filename
output_filename="/home/biqu/printer_data/config/03_Resonances_Measurments/shaper_calibrate_y_ymcmrt0_${time_str}_${date_str}.png"

# Find the most recently created file matching the patterns
latest_file=$(find /tmp -maxdepth 1 -type f \( -name "resonances_y_*.csv" -o -name "calibration_data_y_*.csv" \) -printf "%T@ %p\n" 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)

# Check if a valid file was found
if [ -z "$latest_file" ]; then
  echo "Error: No matching file found for resonances_y_*.csv or calibration_data_y_*.csv"
  exit 1
fi

# Debugging: print the selected file
echo "Using file: $latest_file"

# Run the Python script and capture its output
shaper_output=$(~/klipper/scripts/calibrate_shaper.py "$latest_file" -o "$output_filename")

# Print the output filename
echo "Output file: $output_filename"

# Extract the recommended shaper type and frequency
recommended_shaper=$(echo "$shaper_output" | grep "Recommended shaper" | awk '{print $4}')
recommended_freq=$(echo "$shaper_output" | grep "Recommended shaper" | awk '{print $6}')

# Check if extraction was successful
if [ -z "$recommended_shaper" ] || [ -z "$recommended_freq" ]; then
  echo "Error: Could not extract recommended shaper or frequency"
  exit 1
fi

# Define the configuration file path
config_file="/home/biqu/printer_data/config/variables.cfg"

# Backup the configuration file as a hidden file
cp "$config_file" "/home/biqu/printer_data/config/.variables.cfg.bak"

# Update or add the shaper settings
if grep -q "^shaper_type_ymcmrt0" "$config_file"; then
  # Update existing entries
  sed -i "s/^shaper_type_ymcmrt0.*/shaper_type_ymcmrt0 = '$recommended_shaper'/" "$config_file"
else
  # Add new entry with a newline
  echo -e "\nshaper_type_ymcmrt0 = '$recommended_shaper'" >> "$config_file"
fi

if grep -q "^shaper_freq_ymcmrt0" "$config_file"; then
  # Update existing entries
  sed -i "s/^shaper_freq_ymcmrt0.*/shaper_freq_ymcmrt0 = $recommended_freq/" "$config_file"
else
  # Add new entry with a newline
  echo "shaper_freq_ymcmrt0 = $recommended_freq" >> "$config_file"
fi

# Ensure proper formatting by adding a newline after the last variable if needed
sed -i -e '$a\' "$config_file"

echo "Recommended shaper settings updated in $config_file"
echo "Backup saved as /home/biqu/printer_data/config/.variables.cfg.bak"
