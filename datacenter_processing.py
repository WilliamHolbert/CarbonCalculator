import pandas as pd
import pgeocode as geo

class DatacenterProcessing:
    def __init__(self):
        self.datacenters = self.load_datacenters()
        self.indexs = ["Name", "Region", "Year", "PUE", "Size (m^2)", "Zip", "City", "State", "lat", "Lln"]
        self.currentIndex = 0
        self.seed = 12345
        self.nomi = geo.Nominatim('US')

    def load_datacenters(self):
        temp = pd.read_csv("Data/datacenter_data.csv")
        temp = temp[temp["Country"] == "United States"]
        temp = temp[["Name", "Region", "Year", "PUE", "Size (m^2)", "Zip", "City", "State", "lat", "lon"]]
        return temp

    def add_datacenter(self, name, region, year_built, pue, size, zip):
        row = [name, region, year_built, pue, size, zip]
        city, state, lat, long = get_latlong(city, state, zip)
        row.append(city)
        row.append(state)
        row.append(lat)
        row.append(long)
        row_series = pd.Series(row, index = indexes)
        self.datacenters.append(row_series)

    def get_datacenters(self):
        return self.datacenters

    def get_lat_long(self, zip_code):
        result = self.nomi.query_postal_code(zip_code)
        return result['place_name'], result['state_name'], result['latitude'], result['longitude']
