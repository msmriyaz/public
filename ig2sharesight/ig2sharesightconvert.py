#!/usr/bin/env python3
import csv
import json

def convert_currency(usd_aud):
    if not usd_aud or float(usd_aud) == 0:
        return 0
    usd_aud = float(usd_aud)
    aud_usd = 1 / usd_aud
    return aud_usd

def map_trade_history_to_template(trade_history_file, template_file, output_file, ticker_json_file):
    with open(ticker_json_file) as f:
        tickers = json.load(f)

    with open(trade_history_file) as f:
        trade_histories = csv.DictReader(f)

        with open(template_file) as f:
            template = csv.DictReader(f)
            fieldnames = template.fieldnames

            with open(output_file, "w", newline="") as f:
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()

                buy_count = 0
                sell_count = 0

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
                            print(f"No information found for {market} in the collection of tickers.")
                        elif stock is None or exchange is None:
                            print(f"Stock information for {market} is not available")

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

            f.close()
			
    print("Buy transactions: ", buy_count)
    print("Sell transactions: ", sell_count)

if __name__ == "__main__":
    trade_history_file = "drop/TradeHistory.csv"
    template_file = "template/bulk_trades_template.csv"
    output_file = "output/bulk_trades.csv"
    ticker_json_file = "settings/stock_ticker_json.json"
    map_trade_history_to_template(trade_history_file, template_file, output_file, ticker_json_file)
