### Functions Used in App ###
#
# Series of functions used in main App.R
#

state_breakdown <- read.csv("/cloud/project/Data/state_energy_data.csv")

#### Main Forecast Function ####
carbon_forecast <- function(num_of_years, num_new_datacenters, region_breakdown){
  total_num_datacenters = 0
  
  carbon_pred_by_year = c()
  cost_by_year = c()
  
  for(year in 1:num_of_years){
    
  }  
  
  return(carbon_pred_by_year, cost_by_year)
}


#### Carbon Forecast Function ####
carbon_calculation_datacener <- function(PUE, area_m2, city, state, zip, watts_per_sqft = 400){
  total_carbon = 0
  
  area_sqft = area * 10.7639 # converts m^2 to sqft
  
  total_energy_per_year = (watts_per_sqft/1000)* PUE *24*365
  energy_breakdown = energy_lookup(city, state, zip)
  prec_non_renewable <- energy_breakdown[1] + energy_breakdown[2] + energy_breakdown[3]
  
  total_carbon = total_energy_per_year * energy_breakdown[0] * 0.000004 + # Nuclear
                 total_energy_per_year * energy_breakdown[1] * 0.001    + # Coal
                 total_energy_per_year * energy_breakdown[2] * 0.000549 + # Natural Gas
                 total_energy_per_year * energy_breakdown[3] * 0.000966 + # Petroleum 
                 total_energy_per_year * energy_breakdown[4] * 0.000024 + # Hydro
                 total_energy_per_year * energy_breakdown[5] * 0.000122 + # Geothermal
                 total_energy_per_year * energy_breakdown[5] * 0.00005  + # Solar
                 total_energy_per_year * energy_breakdown[5] * 0.000011 + # Wind
                 total_energy_per_year * energy_breakdown[5] * 0.00023  + # Biomass
  return(total_carbon)
}

#### Energy Look-Up Function ####
energy_lookup <- function(Country, City, State, Zipcode){
  if(Country == 'United States'){
    return(as.numeric(as.vector(state_breakdown[state_breakdown$State==State,])))
  }
  else{
    print("Else")
  }
}

#### Offset Buy Back Amount Function ####
offset_amount <- function(carbon, prec_non_renewable, year){
  
}

#### Monte Carlo Simulation #####
get_sim <- function(num_years){
  source('Plots/Monte_Test.R')
  curr_ts <- 
  
  models <- list(auto.arima(curr_ts))
  result <- arimas_monte(models, n=num_years, n.iter=100)
  result
  
}








