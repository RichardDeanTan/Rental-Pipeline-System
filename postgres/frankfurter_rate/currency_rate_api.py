import requests
import pandas as pd
import time

class CurrencyFetcher:
    def __init__(self, start_date, end_date, base_currency, target_currency):
        self.start_date = start_date
        self.end_date = end_date
        self.base_currency = base_currency
        self.target_currency = target_currency
        self.base_url = "https://api.frankfurter.app"
        self.data = []

    def fetch_monthly_rates(self):
        date_range = pd.date_range(start=self.start_date, end=self.end_date, freq="MS")
        
        for dt in date_range:
            date_str = dt.strftime("%Y-%m-%d")
            url = f"{self.base_url}/{date_str}?from={self.base_currency}&to={self.target_currency}"
            
            response = requests.get(url)
            result = response.json()
            
            if "rates" in result and self.target_currency in result["rates"]:
                rate = result["rates"][self.target_currency]
                self.data.append({
                    "Date": date_str,
                    "Currency From": self.base_currency,
                    "Currency To": self.target_currency,
                    "Exchange Rate": rate
                })
                print(f"[SUCCESS] {date_str} | Exchange Rate: {rate}")
            else:
                print(f"[WARNING] Data tidak ditemukan untuk {date_str}.")
                
            time.sleep(0.1)

    def export_to_csv(self, filename):
        if not self.data:
            print("\n[INFO] Tidak ada data.")
            return
        
        df = pd.DataFrame(self.data)
        df.to_csv(filename, index=False)


def main():
    FILENAME = "postgres/data/currency_rate.csv"
    
    fetcher = CurrencyFetcher(
        start_date="2010-01-01", 
        end_date="2026-07-01", 
        base_currency="USD", 
        target_currency="IDR"
    )
    
    fetcher.fetch_monthly_rates()
    fetcher.export_to_csv(filename=FILENAME)

if __name__ == "__main__":
    main()

# python postgres/frankfurter_rate/currency_rate_api.py