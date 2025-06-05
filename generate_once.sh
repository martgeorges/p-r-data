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
        "P+R" "Max" "Occupées" "Occupation %" \
        "Places Élec" "Occupées" "Occupation %" \
        "Places PMR" "Occupées" "Occupation %"
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
            background-color: #f2f2f2;
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
            height: 245px;
        }
        .box h2 {
            margin-top: 0;
            color: #333;
        }
        .box p {
            color: #555;
        }
    .table-container {
        margin-bottom: 30px;
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

    #début des box et des graphiques
cat <<EOF >> "$HTML_FILE"
    </table>
</div>
<div align="center" style="margin-top: 40px;">
    <h1>P+R graphics</h1>
</div>
<div class="container">
EOF

# Liste des fichiers à traiter
parking_files=(data/parking_B.json data/parking_H.json data/parking_L.json data/parking_M.json data/parking_R.json data/parking_T.json)

gauge_id=1

for file in "${parking_files[@]}"; do
    name=$(jq -r '.name' "$file")
    total=$(jq -r '.totalCapacity' "$file")
    occ_ratio=$(jq -r '.currentTotalOccupancy' "$file")
    occupied=$(printf "%.0f" "$(echo "$total * $occ_ratio" | bc -l)")
    pct_occupied=$(printf "%.0f" "$(echo "$occ_ratio * 100" | bc -l)")


    cat <<EOF >> "$HTML_FILE"
    <div class="box">
        <h2>$name</h2>
        <div id="gauge-container">
            <div id="gauge-$gauge_id" class="200x160px">
                <script>
                var g = new JustGage({
                    id: "gauge-$gauge_id",
                    value: $occupied,
                    min: 0,
                    max: $total,
                    title: "Occupation",
                    label: "($pct_occupied%)"
                });
                </script>
            </div>
        </div>
    </div>
EOF
    #retour a la ligne après la troisième box
    if [[ $gauge_id -eq 3 ]]; then
        cat <<EOF >> "$HTML_FILE"
</div>
<div class="container" style="margin-top: 30px;">
EOF
    fi

    ((gauge_id++))
done

# Clôture HTML
cat <<EOF >> "$HTML_FILE"
</div>
</body>
</html>
EOF

echo "---> [OK] ✅"


#changement a faire ->

#boutons std -> % (working on it)
#logo P+R a ajouter dans l'icon
#couleur CFL sur la page