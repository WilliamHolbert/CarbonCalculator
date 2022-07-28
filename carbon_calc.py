import pandas as pd

class CarbonCalc:
    def __init__(self):
        self.total_carbon = 0
        self.total_cost = 0
        self.prec_non_renewable = [["Year", "Precentage Non-Renewable"]]
        self.historic_carbon_total = 0
        self.historic_cost_total = 0
        self.historic_carbon =  []
        self.historic_cost =  []

        self.carbon_per_year = []
        self.cost_per_year = []

        self.energy_df = pd.read_csv("Data/state_energy_data.csv")

    def get_init_values(self):
        cc_by_buisness_activity = pd.read_csv("Data/ClimateChangeBusinessActivity.csv")
        datacenter_df = cc_by_buisness_activity[cc_by_buisness_activity["Activity"] == "Datacenter"]
        cols = ['Scope 1 emissions (metric tons CO2e)', 'Scope 2, location-based (metric tons CO2e)', 'Scope 2, market-based (metric tons CO2e)']
        datacenter_df['Carbon'] = datacenter_df[cols].sum(axis=1)
        datacenter_df = datacenter_df[datacenter_df["Year (C7.3)"] > 2015]
        datacenter_df = datacenter_df[["Year (C7.3)", "Carbon"]].rename(columns={"Year (C7.3)": "Year"})
        datacenter_df = datacenter_df.astype({"Year": int, "Carbon": int})
        carbon_list = datacenter_df.values.tolist()

        for pair in carbon_list:
            year = pair[0]
            carbon = pair[1]
            self.historic_carbon_total += carbon
            cost = self.calculate_cost(carbon, self.prec_non_renewable, year)
            self.historic_cost_total += cost
            self.historic_carbon.append([year, carbon])
            self.historic_cost.append([year, cost])
        return self.historic_carbon, self.historic_cost, self.historic_carbon_total, self.historic_cost_total


    def reset_values(self):
        self.carbon_per_year = self.historic_carbon
        self.cost_per_year = self.historic_cost

    def calculate(self, num_per_year, end_year, dc_object, datacenter_lifespan = 20, npy = 10, PUE = 1.34, size = 39000):
        self.reset_values()
        dc_df = dc_object.get_datacenters()
        curr_new_data = num_per_year
        for i in range(2022, end_year):
            active_datacenters = dc_df[dc_df["Year"] <= i]
            active_dc_list = active_datacenters.values.tolist()
            curr_year_carbon = 0.0
            curr_prec_non_renewable = 0.0
            for datacenter in active_dc_list[:-1]:
                curr_year_carbon += self.carbon_calculation_datacenter(datacenter[3], datacenter[4], datacenter[6], datacenter[7], datacenter[5])
            for d in range(curr_new_data):
                curr_year_carbon += self.carbon_calculation_datacenter(PUE, size, 'Seattle', 'Washington', '98383')
            self.carbon_per_year.append([i, curr_year_carbon])
            curr_year_cost = self.calculate_cost(curr_year_carbon, curr_prec_non_renewable, i)
            self.cost_per_year.append([i, curr_year_cost])
            curr_new_data += num_per_year
        print(self.carbon_per_year)
        return self.total_carbon, self.total_cost, self.carbon_per_year, self.cost_per_year

    def carbon_calculation_datacenter(self, PUE, area_m2, city, state, zip, watts_per_sqft = 500):
        total_carbon = 0.0
        area_sqft = area_m2 * 10.7639
        total_energy_per_year = watts_per_sqft * PUE * 24 * 365
        enegy_breakdown = self.energy_lookup(city, state, zip)
        prec_non_renewable = enegy_breakdown[1] + enegy_breakdown[2] + enegy_breakdown[3]

        total_carbon = total_energy_per_year * float(enegy_breakdown[1]) * 0.000004 + \
                       total_energy_per_year * float(enegy_breakdown[2]) * 0.001    + \
                       total_energy_per_year * float(enegy_breakdown[3]) * 0.000549 + \
                       total_energy_per_year * float(enegy_breakdown[4]) * 0.000966 + \
                       total_energy_per_year * float(enegy_breakdown[5]) * 0.000024 + \
                       total_energy_per_year * float(enegy_breakdown[6]) * 0.000122 + \
                       total_energy_per_year * float(enegy_breakdown[7]) * 0.00005  + \
                       total_energy_per_year * float(enegy_breakdown[8]) * 0.000011 + \
                       total_energy_per_year * float(enegy_breakdown[9]) * 0.00023
        return total_carbon

    def energy_lookup(self, city, state, zip, year = 2022):
        if year == 2022:
            return self.energy_df.loc[self.energy_df['State'] == state].values.flatten().tolist()
        else:
            print("Year not implemented yet")

    def calculate_cost(self, carbon, prec_non_renewable, year):
        cost = carbon * int(year - 2000)
        return cost

    def get_total_carbon(self):
        return self.total_carbon

    def get_total_cost(self):
        return self.total_cost

    def get_carbon_per_year(self):
        return self.carbon_per_year

    def get_cost_per_year(self):
        return self.cost_per_year
