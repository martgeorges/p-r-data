
#!/bin/bash

mkdir -p data
HTML_FILE="index.html"

clear
echo "---------------------- $(date) ------------------------"

# Téléchargement JSON
curl -s "https://pr-mobile-a.cfl.lu/OpenData/ParkAndRide/RDWRW" -o data/parking_R.json
curl -s "https://pr-mobile-a.cfl.lu/OpenData/ParkAndRide/FQMPE" -o data/parking_M.json
curl -s "https://pr-mobile-a.cfl.lu/OpenData/ParkAndRide/YAX3J" -o data/parking_B.json
curl -s "https://pr-mobile-a.cfl.lu/OpenData/ParkAndRide/P8K2N" -o data/parking_L.json
curl -s "https://pr-mobile-a.cfl.lu/OpenData/ParkAndRide/TWVD3" -o data/parking_T.json
curl -s "https://pr-mobile-a.cfl.lu/OpenData/ParkAndRide/MZJDR" -o data/parking_H.json

printf "+----------------------------+------------+----------+---------------+------------------+------------+----------------+------------------+------------+----------------+\n"
printf "| %-26s | %-10s | %-9s | %-13s | %-17s | %-11s | %-14s | %-16s | %-11s | %-14s |\n" \
    "P+R" "Max" "Occupées" "Occupation %" "Places Élec" "Occupées" "Occupation %" "Places PMR" "Occupées" "Occupation %"
printf "+----------------------------+------------+----------+---------------+------------------+------------+----------------+------------------+------------+----------------+\n"

cat <<EOF > "$HTML_FILE"
<html>
<head>
    <meta http-equiv="refresh" content="30">
    <title>P+R Lux</title>
    <script src="justgage/raphael-2.1.4.min.js"></script>
    <script src="justgage/justgage.js"></script>
    <link rel="shortcut icon" href="img/p-r-logo.jpg">
    <style>
        body {
            margin: 0;
            padding: 20px;
            font-family: Arial, sans-serif;
            background-color: #E6E6E6;
        }
        .container {
            display: flex;
            justify-content: space-between;
            gap: 20px;
        }
        #gauge-container {
            width: 200px;
            height: 160px;
            margin: auto;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .box {
            flex: 1;
            background-color: white;
            border: 1px solid #ccc;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            text-align: center;
            height: 260px;
            position: relative;
        }
        .box h2 {
            margin-top: 10px;
            color: #333;
        }
        .table-container {
            margin-bottom: 0;
            max-width: 100%;
            overflow-x: auto;

        }
        table {
            width: 100%;
            border-collapse: collapse;
            border-radius: 10px;
            overflow: hidden;
        }
        th {
            background-color: #e0e0e0;
            color: #333;
            padding: 10px;
            text-align: center;
        }
        td {
            background-color: #fff;
            padding: 8px;
            text-align: center;
            border-top: 1px solid #ddd;
        }
        tr:nth-child(even) td {
            background-color: #f9f9f9;
        }

        /* Toggle switch */
        .switch-wrapper {
            position: absolute;
            top: 10px;
            left: 10px;
        }
        .switch {
            position: relative;
            display: inline-block;
            width: 70px;
            height: 35px;
        }
        .switch input {
            opacity: 0;
            width: 0;
            height: 0;
        }
        .slider {
            position: absolute;
            cursor: pointer;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-color: #ccc;
            border-radius: 30px;
            transition: .4s;
        }
        .slider:before {
            position: absolute;
            content: "";
            height: 29px;
            width: 30px;
            left: 4px;
            bottom: 3px;
            background-color: white;
            transition: .4s;
            border-radius: 50%;
        }
        input:checked + .slider {
            background-color: #BF0A30;
        }
        input:checked + .slider:before {
            transform: translateX(32px);
        }
        .labels {
            position: absolute;
            width: 100%;
            top: 30px;
            font-size: 12px;
            display: flex;
            justify-content: space-between;
            padding: 0 5px;
            color: #666;
        }

        .header-toggle {
            position: relative;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-top: 40px;
        }

        .switch.large-toggle {
            position: absolute;
            left: 10px;
            top: 50%;
            transform: translateY(-50%);
        }

        .linear-wrap { margin-top: 8px; }
.lg-row { margin: 6px 0; }
.linear-gauge {
  width: 100%;
  height: 18px;
  background: #ccc;
  border-radius: 999px;
  position: relative;
  overflow: hidden;
  box-shadow: inset 0 0 0 1px rgba(0,0,0,0.05);
}
.linear-gauge .fill {
  height: 100%;
  width: 0%;
  transition: width .6s ease;
}
.fill.pmr  { background: #6C8CFF; }   /* PMR = bleu */
.fill.elec { background: #00B894; }   /* Élec = vert */

/* Texte à l’intérieur de la barre */
.linear-gauge .label {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 12px;
  font-weight: bold;
  color: #fff;
  text-shadow: 0 0 2px rgba(0,0,0,0.4);
}
    </style>
</head>
<body>
    <div align="center">
        <h1>P+R data - $(TZ=Europe/Brussels date '+%Y-%m-%d %H:%M:%S (Luxembourg)')</h1>
    <div class="table-container">
    <table border="0" cellspacing="0" cellpadding="5">
        <tr>
            <th>P+R</th>
            <th>Max Capacity</th>
            <th>Occupied</th>
            <th>% Occupied</th>
            <th>Max Capacity elec</th>
            <th>Elec occ.</th>
            <th>% Elec occ.</th>
            <th>Max Capacity PMR</th>
            <th>PMR occ.</th>
            <th>% PMR occ.</th>
        </tr>
EOF

for file in data/parking_*.json; do
    name=$(jq -r '.name' "$file")
    total=$(jq -r '.totalCapacity' "$file")
    occ_ratio=$(jq -r '.currentTotalOccupancy' "$file")
    occupied=$(printf "%.0f" "$(echo "$total * $occ_ratio" | bc -l)")
    pct_occupied=$(printf "%.0f" "$(echo "$occ_ratio * 100" | bc -l)")

    pmr_tot=$(jq -r '.totalPMRCapacity' "$file")
    pmr_occ_ratio=$(jq -r '.currentPMROccupancy' "$file")
    pmr_occ=$(printf "%.0f" "$(echo "$pmr_tot * $pmr_occ_ratio" | bc -l)")
    pct_pmr=$(printf "%.0f" "$(echo "$pmr_occ_ratio * 100" | bc -l)")

    elec_tot=$(jq -r '.totalECarCapacity' "$file")
    elec_occ_ratio=$(jq -r '.currentECarOccupancy' "$file")
    elec_occ=$(printf "%.0f" "$(echo "$elec_tot * $elec_occ_ratio" | bc -l)")
    pct_elec=$(printf "%.0f" "$(echo "$elec_occ_ratio * 100" | bc -l)")

    printf "| %-26s | %-10s | %-8s | %-13s | %-16s | %-10s | %-14s | %-16s | %-10s | %-14s |\n" \
        "$name" "$total" "$occupied" "$pct_occupied%" \
        "$elec_tot" "$elec_occ" "$pct_elec%" \
        "$pmr_tot" "$pmr_occ" "$pct_pmr%"

    printf "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s%%</td><td>%s</td><td>%s</td><td>%s%%</td><td>%s</td><td>%s</td><td>%s%%</td></tr>\n" \
        "$name" "$total" "$occupied" "$pct_occupied" \
        "$elec_tot" "$elec_occ" "$pct_elec" \
        "$pmr_tot" "$pmr_occ" "$pct_pmr" >> "$HTML_FILE"
done

printf "+----------------------------+------------+----------+---------------+------------------+------------+----------------+------------------+------------+----------------+\n"

cat <<EOF >> "$HTML_FILE"
    </table>
</div>
<div class="header-toggle" style="display: flex; align-items: center; justify-content: center; margin-top: 5px; gap: 20px;">
    <h1 style="margin: 15px;">P+R graphics</h1>
    <label class="switch large-toggle">
        <input type="checkbox" id="globalToggle">
        <span class="slider"></span>
        <span class="labels" data-on="%" data-off="#"> </span>
    </label>
</div>

<div class="container">
EOF

parking_files=(data/parking_B.json data/parking_H.json data/parking_L.json data/parking_M.json data/parking_R.json data/parking_T.json)
gauge_id=1

for file in "${parking_files[@]}"; do
    name=$(jq -r '.name' "$file")
    total=$(jq -r '.totalCapacity' "$file")
    occ_ratio=$(jq -r '.currentTotalOccupancy' "$file")
    occupied=$(printf "%.0f" "$(echo "$total * $occ_ratio" | bc -l)")
    pct_occupied=$(printf "%.0f" "$(echo "$occ_ratio * 100" | bc -l)")

    pmr_tot=$(jq -r '.totalPMRCapacity' "$file")
    pmr_occ_ratio=$(jq -r '.currentPMROccupancy' "$file")
    pmr_occ=$(printf "%.0f" "$(echo "$pmr_tot * $pmr_occ_ratio" | bc -l)")
    pct_pmr=$(printf "%.0f" "$(echo "$pmr_occ_ratio * 100" | bc -l)")

    elec_tot=$(jq -r '.totalECarCapacity' "$file")
    elec_occ_ratio=$(jq -r '.currentECarOccupancy' "$file")
    elec_occ=$(printf "%.0f" "$(echo "$elec_tot * $elec_occ_ratio" | bc -l)")
    pct_elec=$(printf "%.0f" "$(echo "$elec_occ_ratio * 100" | bc -l)")

    cat <<EOF >> "$HTML_FILE"
    <div class="box">
        <h2>$name</h2>
        <div id="gauge-container">
            <div id="gauge-$gauge_id" class="200x160px"></div>
        </div>
        <input type="hidden" class="gauge-data" data-gauge="gauge-$gauge_id" data-occupied="$occupied" data-percent="$pct_occupied" data-max="$total">
        <script>
            var gauge_$gauge_id = new JustGage({
                id: "gauge-$gauge_id",
                value: $occupied,
                min: 0,
                max: $total,
                title: "Occupation",
            });
            setTimeout(function () {
            /*gauge_$gauge_id.txtValue.attr({ "font-size": "25px" });*/
            gauge_$gauge_id.txtMin.attr({ "font-size": "18px" });
            gauge_$gauge_id.txtMax.attr({ "font-size": "18px" });
            
        }, 100);
        </script>
            <div class="linear-wrap">
      <!-- PMR -->
      <div class="lg-row">
        <div class="linear-gauge">
          <div class="fill pmr" style="width: ${pct_pmr}%"></div>
          <div class="label">PMR: $pmr_occ / $pmr_tot (${pct_pmr}%)</div>
        </div>
      </div>

      <!-- Électriques -->
      <div class="lg-row">
        <div class="linear-gauge">
          <div class="fill elec" style="width: ${pct_elec}%"></div>
          <div class="label">Élec: $elec_occ / $elec_tot (${pct_elec}%)</div>
        </div>
      </div>
    </div>

    </div>
EOF

    if [[ $gauge_id -eq 3 ]]; then
        echo "</div><div class=\"container\" style=\"margin-top: 30px;\">" >> "$HTML_FILE"
    fi

    ((gauge_id++))
done

cat <<EOF >> "$HTML_FILE"
</div>

<script>
document.getElementById('globalToggle').addEventListener('change', function() {
    var isChecked = this.checked;

    document.querySelectorAll('.gauge-data').forEach(function(input) {
        var gaugeId = input.dataset.gauge;
        var gauge = window["gauge_" + gaugeId.split('-')[1]];
        var occupied = parseInt(input.dataset.occupied);
        var percent = parseInt(input.dataset.percent);
        var max = parseInt(input.dataset.max);

        if (isChecked) {
            gauge.config.max = 100;
            gauge.config.symbol = "%";
            gauge.refresh(percent);
            /*gauge.txtValue.attr({ "text": percent + "%" });*/
            /*gauge.txtLabel.attr({ "text": "% Occupation" });*/
            gauge.txtMax.attr({ "text": "100" });
        } else {
            gauge.config.max = max;
            gauge.config.symbol = ""; 
            gauge.refresh(occupied);
            /*gauge.txtLabel.attr({ "text": "Occupation" });*/
            gauge.txtMax.attr({ "text": max.toString() });
        }
    });
});
</script>

</body>
</html>
EOF
echo "---> [OK] ✅"