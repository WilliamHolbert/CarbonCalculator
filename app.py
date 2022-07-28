from multiapp import MultiApp
import streamlit as st
import sim, home
app = MultiApp()

app.add_app("Home", home.app)
app.add_app("Simulation", sim.app)
#app.add_app("Bar", bar.app)

app.run()
