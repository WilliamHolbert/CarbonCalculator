import pandas as pd
import altair as alt
from millify import millify
import streamlit as st
from datacenter_processing import DatacenterProcessing
from carbon_calc import CarbonCalc

class App:
    def __init__(self):
        self.dp = DatacenterProcessing()
        self.cc = CarbonCalc()

        self.historic_carbon, self.historic_cost, self.historic_carbon_total, self.historic_cost_total = self.cc.get_init_values()

        # Input Params
        self.datacenters = self.dp.load_datacenters()
        self.new_per_year = 10
        self.number_of_years = 10
        self.average_size = 39000
        self.average_pue = 1.34
        self.breakdown = []

        ## Regions
        self.region_east_us          = 0.11
        self.region_east_us_2        = 0.06
        self.region_east_us_3        = 0.09
        self.region_central_us       = 0.04
        self.region_north_central_us = 0.11
        self.region_soutn_central_us = 0.11
        self.region_west_central_us  = 0.09
        self.region_west_us          = 0.22
        self.region_west_us_2        = 0.11
        self.region_west_us_3        = 0.06

        # Output Variables
        self.headers_carbon = ["Year", "Carbon"]
        self.headers_cost = ["Year", "Cost"]
        self.all_carbon = self.historic_carbon_total
        self.all_cost = self.historic_cost_total
        self.year_to_carbon = self.historic_carbon
        self.year_to_cost = self.historic_cost
        self.errors = False

        self.re_calculate('init')

    def run_ui(self):
        st.title("Datacenter Map")

        # Output Metrics
        with st.sidebar:
            if st.checkbox("Auto Simulation"):
                with st.sidebar.form(key = "auto_form"):
                    # Input Parameters for General
                    st.write("Auto Simulation")
                    self.new_per_year = st.number_input("Set number of new datacenters per year",
                                    value = 10, min_value = 1, max_value = 100, step = 1, format = "%i")
                    self.number_of_years = st.number_input("Set Number of Years to Project",
                                    value = 10, min_value = 1, max_value = 100, step = 1, format = "%i")
                    self.average_size = st.number_input("Average Datacenter Size in Meters Squared",
                                    value = 39000, min_value = 0, max_value = 1000000, step = 1000, format = "%i")
                    self.average_pue = st.number_input("Average Datacenter PUE (Power Usage Effectiveness)",
                                    value = 1.34, min_value = 0.0, max_value = 10.0, step = 0.01, format = "%f")

                    with st.expander("Region Breakdown"):
                        self.region_east_us          = st.number_input("East US",          value = 0.09, min_value = 0.0, max_value = 1.0, step = 0.01)
                        self.region_east_us_2        = st.number_input("East US 2",        value = 0.06, min_value = 0.0, max_value = 1.0, step = 0.01)
                        self.region_east_us_3        = st.number_input("East US 3",        value = 0.09, min_value = 0.0, max_value = 1.0, step = 0.01)
                        self.region_central_us       = st.number_input("Central US",       value = 0.04, min_value = 0.0, max_value = 1.0, step = 0.01)
                        self.region_north_central_us = st.number_input("North Central US", value = 0.11, min_value = 0.0, max_value = 1.0, step = 0.01)
                        self.region_soutn_central_us = st.number_input("South Central US", value = 0.11, min_value = 0.0, max_value = 1.0, step = 0.01)
                        self.region_west_central_us  = st.number_input("West Central US",  value = 0.09, min_value = 0.0, max_value = 1.0, step = 0.01)
                        self.region_west_us          = st.number_input("West US",          value = 0.22, min_value = 0.0, max_value = 1.0, step = 0.01)
                        self.region_west_us_2        = st.number_input("West US 2",        value = 0.11, min_value = 0.0, max_value = 1.0, step = 0.01)
                        self.region_west_us_3        = st.number_input("West US",          value = 0.06, min_value = 0.0, max_value = 1.0, step = 0.01)
                    pressed_1 = st.form_submit_button("Run Simulation")
            if st.checkbox("Custom Simulation"):
                with st.sidebar.form(key = "cust_form"):
                    self.datacenter_size = st.number_input("Set Size of Datacenter", value = 1000, min_value = 0, max_value = 100000, step = 1000, format = "%i")
                    pressed_2 = st.form_submit_button("Run Custom Simulation")


            if pressed_1 and self.errors == False:
                self.re_calculate('auto')
            if pressed_2:
                self.re_calculate('custom')

        map = st.map(self.datacenters)
        st.title("Current Projections")

        ca = alt.Chart(pd.DataFrame(self.year_to_carbon, columns = self.headers_carbon)).mark_line().encode(y='Carbon', x='Year:N')
        co = alt.Chart(pd.DataFrame(self.year_to_cost, columns = self.headers_cost)).mark_line().encode(y='Cost', x='Year:N')



        st.altair_chart((ca).interactive(), use_container_width=True)
        st.altair_chart((co).interactive(), use_container_width=True)


    def re_calculate(self, type):
        end_year = 2022 + self.number_of_years
        temp_total_carbon, temp_total_cost, temp_carbon_per_year, temp_cost_per_year =  self.cc.calculate(self.number_of_years, end_year, self.dp, npy= self.new_per_year, PUE = self.average_pue, size = self.average_size)
        #print(temp_carbon_per_year, temp_cost_per_year)

        self.year_to_carbon = self.historic_carbon + temp_carbon_per_year
        self.year_to_cost = self.historic_cost + temp_cost_per_year
        self.all_carbon = self.historic_carbon_total + temp_total_carbon
        self.all_cost = self.historic_cost_total + temp_total_cost


def app():
    app = App()
    app.run_ui()
