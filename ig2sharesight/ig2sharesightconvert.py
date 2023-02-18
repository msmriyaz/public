#!/usr/bin/env python3
import csv
import json
import os

def convert_currency(usd_aud):
    if not usd_aud or float(usd_aud) == 0:
        return 0
    usd_aud = float(usd_aud)
    aud_usd = 1 / usd_aud
    return aud_usd

def map_trade_history_to_template(template_file, output_folder, ticker_json_file):
    with open(ticker_json_file) as f:
        tickers = json.load(f)

    # Find the most recent file in the drop folder starting with TradeHistory and ending with .csv
    files = [f for f in os.listdir("drop") if f.startswith("TradeHistory") and f.endswith(".csv")]
    if not files:
        print("No TradeHistory files found in the drop folder")
        return
    trade_history_file = sorted(files, reverse=True)[0]
    print(f"Using {trade_history_file} as the TradeHistory file")

    with open(f"drop/{trade_history_file}") as fd:
        trade_histories = csv.DictReader(fd)

        date_range = ""
        start_date = None
        end_date = None
        for trade_history in trade_histories:
            try:
                trade_date = trade_history["Date"]
            except KeyError:
                trade_date = trade_history["\ufeffDate"]
            if not start_date or trade_date < start_date:
                start_date = trade_date
            if not end_date or trade_date > end_date:
                end_date = trade_date

        if start_date and end_date:
            date_range = "_" + start_date.replace("/", "_") + "_" + end_date.replace("/", "_")


        with open(template_file) as ft:
            template = csv.DictReader(ft)
            fieldnames = template.fieldnames

            output_file = f"{output_folder}/bulk_trades{date_range}.csv"
            with open(output_file, "w", newline="") as fo:
                writer = csv.DictWriter(fo, fieldnames=fieldnames)
                writer.writeheader()

                buy_count = 0
                sell_count = 0

                fd.seek(0)
                trade_histories = csv.DictReader(fd)
                for trade_history in trade_histories:
                    try:
                        trade_date = trade_history["Date"]                        
                    except KeyError:
                        trade_date = trade_history["\ufeffDate"]
                    market = trade_history["Market"]
                    direction = trade_history["Direction"].lower()
                    quantity = trade_history["Quantity"]                    
                    try:
                        price = abs(float(trade_history["Consideration"])) / abs(float(trade_history["Quantity"]))
                    except ValueError:
                        price = 0                    
                    currency = trade_history["Currency"]
                    try:
                        commission = abs(float(trade_history["Commission"]))
                    except ValueError:
                        commission = 0
                    try:
                        charges = abs(float(trade_history["Charges"]))
                    except ValueError:
                        charges = 0

                    brokerage = commission + charges                    
                    conversion_rate = convert_currency(trade_history["Conversion rate"])

                    stock = None
                    exchange = None
                    found = False
                    if (None != market and '' != market):
                        for ticker in tickers:
                            if ticker["name"] == market:
                                stock = ticker["stock"]
                                exchange = ticker["exchange"]
                                found = True
                                break
                        if not found:
                            print(f"No information found for '{market}' in the collection of tickers.")
                        elif stock is None or exchange is None:
                            print(f"Stock information for '{market}' is not available")

                    transaction_type = None
                    if direction == "buy":
                        transaction_type = "Buy"
                        buy_count += 1
                    elif direction == "sell":
                        transaction_type = "Sell"
                        sell_count += 1

                    if (None != stock and None != exchange and None != transaction_type):
                        writer.writerow({
                            "Trade Date": trade_date,
                            "Instrument Code": stock,
                            "Market Code": exchange,
                            "Quantity": quantity,
                            "Price": price,
                            "Transaction Type": transaction_type,
                            "Exchange Rate (optional)": conversion_rate,
                            "Brokerage (optional)": brokerage,
                            "Brokerage Currency (optional)": currency,
                            "Comments (optional)": ""
                        })

            fo.close()
			
    print("Buy transactions: ", buy_count)
    print("Sell transactions: ", sell_count)

if __name__ == "__main__":
    #trade_history_file = "drop/TradeHistory.csv"
    template_file = "template/bulk_trades_template.csv"
    output_folder = "output"
    ticker_json_file = "settings/stock_ticker_json.json"
    #map_trade_history_to_template(trade_history_file, template_file, output_file, ticker_json_file)
    map_trade_history_to_template(template_file, output_folder, ticker_json_file)
