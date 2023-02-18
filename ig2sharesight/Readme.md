# Trade History Mapper

This Python 3 script maps trade history data in a CSV file to a template in another CSV file and generates an output file with the mapped data. The code also depends on a JSON file that contains information about the stocks and their tickers.

## Folder Structure
- The root folder contains the main code file, `convert_trade_history.py`, and the following sub-folders:
  - `drop`: contains the input CSV file with trade history data
  - `template`: contains the template CSV file to be used for mapping the trade history data
  - `output`: contains the output file generated by the code after mapping the trade history data to the template
  - `settings`: contains the JSON file with information about the stocks and their tickers
  
## Code Dependencies
The code depends on the following libraries:
- `csv`: used to read and write CSV files
- `json`: used to read the JSON file with stock information

## Testing
To test the code, you can follow these steps:
1. Place the input CSV file with trade history data in the `drop` folder.
2. Place the template CSV file in the `template` folder.
3. Place the JSON file with stock information in the `settings` folder.
4. Run the code using the following command:
`python3 convert_trade_history.py`
5. The output file will be generated in the `output` folder.

## Autho notes:
To run this program locally
- `cd /devops/pydev`
- `source venv/bin/activate`
- `cd /venv/ig2sharesight`
- `python ig2sharesightconvert.py`