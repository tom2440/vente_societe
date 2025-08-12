Config = {}

-- Option pour utiliser ou non ox_target
Config.UseTarget = true -- true pour utiliser ox_target, false pour utiliser le système par proximité

-- Ajoute la société du gouvernement et le pourcentage ici
Config.Society = 'society_realestateagent'  -- Le compte société pour le gouvernement
Config.Percentage = 0.07  -- Le pourcentage à transférer au gouvernement (7%)

-- Webhooks pour les logs Discord
Config.WebhookSocietyBought = ""  -- Webhook pour l'achat d'une société
Config.WebhookSocietyForSale = ""  -- Webhook pour la mise en vente d'une société

-- Configuration du PED d'agent immobilier de sociétés
Config.AgentCoords = vector4(-238.1617, -920.8577, 32.3122, 307.8820)  -- Position de l'agent (x, y, z, heading)
Config.AgentPed = 's_m_m_highsec_01'  -- Modèle du PED

-- Configuration du Blip sur la carte
Config.AgenceSocieter = {
    Blip = {
      Pos     = {x = -238.52, y = -920.48, z = 31.31},  -- Position du blip sur la carte
      Sprite  = 374,  -- Sprite du blip (icône)
      Display = 0,    -- Type d'affichage
      Scale   = 0.0,  -- Taille du blip 
      Colour  = 2,    -- Couleur du blip (2 = vert)
    },
}

-- Liste des métiers disponibles avec leur grade maximum et description
Config.Jobs = {
    jobs = {
        taxi = {label = "Taxi", grade = 4, description = "Service de transport de passagers."},
        police = {label = "Police", grade = 4, description = "Forces de l'ordre et sécurité publique."},
        cardealer = {label = "Concessionnaire", grade = 3, description = "Vente de véhicules."}
        -- ajouter ici
    }
}

-- Images pour les sociétés (à afficher dans le menu)
Config.SocietyImages = {
    --taxi = "https://r2.fivemanage.com/",
    --police = "https://r2.fivemanage.com/",
    -- ajouter ici
    
}