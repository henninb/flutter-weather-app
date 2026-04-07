package com.weather.minneapolis_weather

import android.app.Application

class MainApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        HumanManager.start(this)
    }
}
