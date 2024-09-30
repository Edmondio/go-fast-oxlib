Config = {}

Config.Language = 'fr' -- fr ou en  

Config.GlobalCooldown = 1800 -- 30 minutes en secondes timer pour tous les joueurs
Config.PlayerCooldown = 3600 -- 1 heure en secondes timer pour chaque joueur

Config.PedLocation = vector4(1086.514, -2400.004, 30.575, 265.33)
Config.PedModel = `a_m_y_business_03`
Config.VehicleSpawnPoint = vector4(1079.645, -2385.448, 29.997, 359.73)

Config.VehicleModels = {'sultan', 'kuruma', 'buffalo'}

Config.DrugTypes = {
    {name = 'cocaine', label = 'Cocaïne', rewardPerUnit = 50, maxAmount = 500, minAmount = 10},
    {name = 'meth', label = 'Méthamphétamine', rewardPerUnit = 60, maxAmount = 500, minAmount = 10},
    {name = 'weed', label = 'Cannabis', rewardPerUnit = 30, maxAmount = 500, minAmount = 10},
}

Config.DeliveryPoints = {
    vector3(809.005, 2180.060, 52.007),
    vector3(2465.861, 1588.717, 32.720),
    -- Ajoutez d'autres points selon vos besoins
}

Config.TypeMoney = 'money' -- le type de money que le joueur va recevoir

Config.TimerBeforeAlert = {min = 10, max = 10}
Config.PoliceAlertDuration = {min = 10, max = 10}
Config.PoliceUpdateInterval = 10 -- Intervalle en secondes pour l'envoi de la position aux policiers
Config.PoliceBlipDuration = 5 -- Durée en secondes pendant laquelle le blip reste visible

Config.PoliceJobName = 'police'
Config.MinPolice = 1

Config.OxNotifyPosition = 'top'