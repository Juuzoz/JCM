extends Node

const WEAPONS = {
    # Pistols
    "Makarov": "res://Items/Weapons/Makarov/Makarov.tres",
    "Colt 1911": "res://Items/Weapons/Colt_1911/Colt_1911.tres",
    "Glock 17": "res://Items/Weapons/Glock_17/Glock_17.tres",
    "P320": "res://Items/Weapons/P320/P320.tres",
    
    # SMGs
    "MP5": "res://Items/Weapons/MP5/MP5.tres",
    "MP5K": "res://Items/Weapons/MP5K/MP5K.tres",
    "MP5SD": "res://Items/Weapons/MP5SD/MP5SD.tres",
    "MP7": "res://Items/Weapons/MP7/MP7.tres",
    "KP-31": "res://Items/Weapons/KP-31/KP-31.tres",
    "AKS-74U": "res://Items/Weapons/AKS-74U/AKS-74U.tres",
    
    # Assault Rifles
    "AKM": "res://Items/Weapons/AKM/AKM.tres",
    "AK-12": "res://Items/Weapons/AK-12/AK-12.tres",
    "M4A1": "res://Items/Weapons/M4A1/M4A1.tres",
    "MK18": "res://Items/Weapons/MK18/MK18.tres",
    "HK416": "res://Items/Weapons/HK416/HK416.tres",
    "RK-62": "res://Items/Weapons/RK-62/RK-62.tres",
    "RK-62M": "res://Items/Weapons/RK-62/RK-62M.tres",
    "RK-95": "res://Items/Weapons/RK-95/RK-95.tres",
    "KAR-21 (.223)": "res://Items/Weapons/KAR-21/KAR-21_223.tres",
    "KAR-21 (.308)": "res://Items/Weapons/KAR-21/KAR-21_308.tres",
    
    # Snipers & Shotguns
    "SVD Sniper": "res://Items/Weapons/SVD/SVD.tres",
    "VSS Vintorez": "res://Items/Weapons/VSS/VSS.tres",
    "M78": "res://Items/Weapons/M78/M78.tres",
    "Mosin": "res://Items/Weapons/Mosin/Mosin.tres",
    "Remington 870": "res://Items/Weapons/Remington_870/Remington_870.tres",
    
    # Knives & Grenades
    "Jaeger 140 Knife": "res://Items/Knives/Jaeger_140/Jaeger_140.tres",
    "Skrama 200 Knife": "res://Items/Knives/Skrama_200/Skrama_200.tres",
    "Skrama 240 Knife": "res://Items/Knives/Skrama_240/Skrama_240.tres",
    "F1 Grenade": "res://Items/Grenades/F1/F1.tres",
    "RGD-5 Grenade": "res://Items/Grenades/RGD-5/RGD-5.tres",
    "M43 Grenade": "res://Items/Grenades/M43/M43.tres",
    "M50 Grenade": "res://Items/Grenades/M50/M50.tres"
}

const MAGAZINES = {
    "Makarov Mag": "res://Items/Weapons/Makarov/Makarov_Magazine.tres",
    "Colt 1911 Mag": "res://Items/Weapons/Colt_1911/Colt_1911_Magazine.tres",
    "Glock 17 Mag": "res://Items/Weapons/Glock_17/Glock_17_Magazine.tres",
    "P320 Mag": "res://Items/Weapons/P320/P320_Magazine.tres",
    "MP5 Mag": "res://Items/Weapons/MP5/MP5_Magazine.tres",
    "MP7 Mag": "res://Items/Weapons/MP7/MP7_Magazine.tres",
    "KP-31 Drum": "res://Items/Weapons/KP-31/KP-31_Drum.tres",
    "AKS-74U Mag": "res://Items/Weapons/AKS-74U/AKS-74U_Magazine.tres",
    "AKM Mag": "res://Items/Weapons/AKM/AKM_Magazine.tres",
    "AK-12 Mag": "res://Items/Weapons/AK-12/AK-12_Magazine.tres",
    "STANAG Mag": "res://Items/Weapons/M4A1/STANAG_Magazine.tres",
    "RK Mag": "res://Items/Weapons/RK-62/RK_Magazine.tres",
    "KAR-21 (.223) Mag": "res://Items/Weapons/KAR-21/KAR-21_223_Magazine.tres",
    "KAR-21 (.308) Mag": "res://Items/Weapons/KAR-21/KAR-21_308_Magazine.tres",
    "M78 Mag": "res://Items/Weapons/M78/M78_Magazine.tres",
    "SVD Mag": "res://Items/Weapons/SVD/SVD_Magazine.tres",
    "VSS Mag": "res://Items/Weapons/VSS/VSS_Magazine.tres"
}

const AMMO = {
    "Ammo 9x18mm": "res://Items/Ammo/Ammo_9x18/Ammo_9x18.tres",
    "Ammo 9x19mm": "res://Items/Ammo/Ammo_9x19/Ammo_9x19.tres",
    "Ammo .45 ACP": "res://Items/Ammo/Ammo_45ACP/Ammo_45ACP.tres",
    "Ammo 9x39mm": "res://Items/Ammo/Ammo_9x39/Ammo_9x39.tres",
    "Ammo 4.6x30mm": "res://Items/Ammo/Ammo_46x30/Ammo_46x30.tres",
    "Ammo 5.56x45mm (.223)": "res://Items/Ammo/Ammo_223/Ammo_223.tres",
    "Ammo 7.62x51mm (.308)": "res://Items/Ammo/Ammo_308/Ammo_308.tres",
    "Ammo 5.45x39mm": "res://Items/Ammo/Ammo_545x39/Ammo_545x39.tres",
    "Ammo 7.62x39mm": "res://Items/Ammo/Ammo_762x39/Ammo_762x39.tres",
    "Ammo 7.62x54mmR": "res://Items/Ammo/Ammo_762x54R/Ammo_762x54R.tres",
    "Ammo 12 Gauge": "res://Items/Ammo/Ammo_12x70/Ammo_12x70.tres"
}

const MEDICAL = {
    "Medkit": "res://Items/Medical/Medkit/Medkit.tres",
    "IFAK": "res://Items/Medical/IFAK/IFAK.tres",
    "AFAK": "res://Items/Medical/AFAK/AFAK.tres",
    "Bandage": "res://Items/Medical/Bandage/Bandage.tres",
    "Improvised Bandage": "res://Items/Medical/Bandage_Improvised/Bandage_Improvised.tres",
    "Tourniquet": "res://Items/Medical/Tourniquet/Tourniquet.tres",
    "Improvised Tourniquet": "res://Items/Medical/Tourniquet_Improvised/Tourniquet_Improvised.tres",
    "Splint": "res://Items/Medical/Splint/Splint.tres",
    "Improvised Splint": "res://Items/Medical/Splint_Improvised/Splint_Improvised.tres",
    "Painkillers": "res://Items/Medical/Painkillers/Painkillers.tres",
    "Antibiotics": "res://Items/Medical/Antibiotics/Antibiotics.tres",
    "Cold Medicine": "res://Items/Medical/Cold_Medicine/Cold_Medicine.tres",
    "Gum": "res://Items/Medical/Gum/Gum.tres",
    "Melatonin": "res://Items/Medical/Melatonin/Melatonin.tres",
    "Antiseptic": "res://Items/Medical/Antiseptic/Antiseptic.tres",
    "Saline": "res://Items/Medical/Saline/Saline.tres",
    "Lotion": "res://Items/Medical/Lotion/Lotion.tres",
    "Balm": "res://Items/Medical/Balm/Balm.tres",
    "Deodorant": "res://Items/Medical/Deodorant/Deodorant.tres",
    "Wipes": "res://Items/Medical/Wipes/Wipes.tres",
    "Tissues": "res://Items/Medical/Tissues/Tissues.tres",
    "Thermal Blanket": "res://Items/Medical/Thermal_Blanket/Thermal_Blanket.tres"
}

const GEAR = {
    # Helmets & Night Vision
    "Helmet SSh-39": "res://Items/Helmets/SSh-39/SSh-39.tres",
    "Helmet Police": "res://Items/Helmets/Helmet_Police/Helmet_Police.tres",
    "PV7 NVG": "res://Items/Electronics/PV7/PV7.tres",
    
    # Armor Plates
    "Armor Plate II": "res://Items/Armor/Armor_Plate_II.tres",
    "Armor Plate IIIA": "res://Items/Armor/Armor_Plate_IIIA.tres",
    "Armor Plate III": "res://Items/Armor/Armor_Plate_III.tres",
    "Armor Plate III+": "res://Items/Armor/Armor_Plate_III+.tres",
    "Armor Plate IV": "res://Items/Armor/Armor_Plate_IV.tres",
    
    # Rigs & Vests
    "Rig LVPC Green": "res://Items/Rigs/LVPC/LVPC_Green.tres",
    "Rig LVPC M05": "res://Items/Rigs/LVPC/LVPC_M05.tres",
    "Rig LVPC Winter": "res://Items/Rigs/LVPC/LVPC_Winter.tres",
    "Rig K19": "res://Items/Rigs/K19/K19.tres",
    "Vest Fishing": "res://Items/Rigs/Vest_Fishing/Vest_Fishing.tres",
    
    # Backpacks
    "Backpack Nomad": "res://Items/Backpacks/Backpack_Nomad/Backpack_Nomad.tres",
    "Backpack Patrol": "res://Items/Backpacks/Backpack_Patrol/Backpack_Patrol.tres",
    "Backpack Jaeger Black": "res://Items/Backpacks/Backpack_Jaeger/Backpack_Jaeger_Black.tres",
    "Backpack Jaeger Brown": "res://Items/Backpacks/Backpack_Jaeger/Backpack_Jaeger_Brown.tres",
    "Backpack Jaeger Green": "res://Items/Backpacks/Backpack_Jaeger/Backpack_Jaeger_Green.tres",
    "Backpack Jaeger M05": "res://Items/Backpacks/Backpack_Jaeger/Backpack_Jaeger_M05.tres",
    "Duffel Retro": "res://Items/Backpacks/Duffel_Retro/Duffel_Retro.tres",
    
    # Belts
    "Belt Kukkaro Black": "res://Items/Belts/Kukkaro/Kukkaro_Black.tres",
    "Belt Kukkaro Brown": "res://Items/Belts/Kukkaro/Kukkaro_Brown.tres",
    "Belt Kukkaro Green": "res://Items/Belts/Kukkaro/Kukkaro_Green.tres",
    "Belt Kukkaro M05": "res://Items/Belts/Kukkaro/Kukkaro_M05.tres",
    
    # Clothing
    "Hat Sauna": "res://Items/Clothing/Hat_Sauna/Hat_Sauna.tres",
    "Hat Mosquito": "res://Items/Clothing/Hat_Mosquito/Hat_Mosquito.tres",
    "Beanie Flame": "res://Items/Clothing/Beanie_Flame/Beanie_Flame.tres",
    "Cap M62": "res://Items/Clothing/Cap_M62/Cap_M62.tres",
    "Jacket M62": "res://Items/Clothing/Jacket_M62/Jacket_M62.tres",
    "Hoodie Gray": "res://Items/Clothing/Hoodie_Gray/Hoodie_Gray.tres",
    "Hoodie Border Zone": "res://Items/Clothing/Hoodie_Border_Zone/Hoodie_Border_Zone.tres",
    "Fleece Tactical Brown": "res://Items/Clothing/Fleece_Tactical_Brown/Fleece_Tactical_Brown.tres",
    "Fleece Tactical Green": "res://Items/Clothing/Fleece_Tactical_Green/Fleece_Tactical_Green.tres",
    "Windbreaker Black": "res://Items/Clothing/Windbreaker_Black/Windbreaker_Black.tres",
    "Windbreaker Green": "res://Items/Clothing/Windbreaker_Green/Windbreaker_Green.tres",
    "Jacket Winter Blue": "res://Items/Clothing/Jacket_Winter_Blue/Jacket_Winter_Blue.tres",
    "Jacket Winter Red": "res://Items/Clothing/Jacket_Winter_Red/Jacket_Winter_Red.tres",
    "Jacket Santa": "res://Items/Clothing/Jacket_Santa/Jacket_Santa.tres",
    "Jeans Black": "res://Items/Clothing/Jeans_Black/Jeans_Black.tres",
    "Pants Hiking": "res://Items/Clothing/Pants_Hiking/Pants_Hiking.tres",
    "Boots Combat": "res://Items/Clothing/Boots_Combat/Boots_Combat.tres",
    "Gloves Leather": "res://Items/Clothing/Gloves_Leather/Gloves_Leather.tres",
    "Gloves Work": "res://Items/Clothing/Gloves_Work/Gloves_Work.tres"
}

const ATTACHMENTS = {
    # Weapon Parts
    "KAR-21 Barrel": "res://Items/Weapons/KAR-21/KAR-21_Barrel.tres",

    # Optics
    "ACOG Scope": "res://Items/Attachments/ACOG/ACOG.tres",
    "EXPS Holo": "res://Items/Attachments/EXPS/EXPS.tres",
    "RMR Sight": "res://Items/Attachments/RMR/RMR.tres",
    "Vudu Scope": "res://Items/Attachments/Vudu/Vudu.tres",
    "PU Scope": "res://Items/Attachments/PU/PU.tres",
    "POSP Scope": "res://Items/Attachments/POSP/POSP.tres",
    "Kobra Sight": "res://Items/Attachments/Kobra/Kobra.tres",
    "PRO Sight": "res://Items/Attachments/PRO/PRO.tres",
    "SRO Sight": "res://Items/Attachments/SRO/SRO.tres",
    "OZ5 Optic": "res://Items/Attachments/OZ5/OZ5.tres",
    "HMR Sight": "res://Items/Attachments/HMR/HMR.tres",
    "Leopard Optic": "res://Items/Attachments/Leopard/Leopard.tres",
    "Micro Sight": "res://Items/Attachments/Micro/Micro.tres",
    "MRO Sight": "res://Items/Attachments/MRO/MRO.tres",
    
    # Lasers & Suppressors
    "ANPEQ Laser": "res://Items/Attachments/ANPEQ/ANPEQ.tres",
    "PTN Suppressor": "res://Items/Attachments/PTN/PTN.tres",
    "Rider Suppressor": "res://Items/Attachments/Rider/Rider.tres",
    "PBS Suppressor": "res://Items/Attachments/PBS/PBS.tres",
    "Thor Suppressor": "res://Items/Attachments/Thor/Thor.tres",
    "Salvo Suppressor": "res://Items/Attachments/Salvo/Salvo.tres",
    "Hybrid Suppressor": "res://Items/Attachments/Hybrid/Hybrid.tres",
    "Monster Suppressor": "res://Items/Attachments/Monster/Monster.tres",
    "Navy Suppressor": "res://Items/Attachments/Navy/Navy.tres",
    "SOCOM Suppressor": "res://Items/Attachments/SOCOM/SOCOM.tres"
}

const FOOD = {
    "Water Bottle": "res://Items/Consumables/Water_Bottle/Water_Bottle.tres",
    "Energy Drink": "res://Items/Consumables/Energy_Drink/Energy_Drink.tres",
    "Soda Lemon": "res://Items/Consumables/Soda_Lemon/Soda_Lemon.tres",
    "Juice Orange": "res://Items/Consumables/Juice_Orange/Juice_Orange.tres",
    "Juice Pear": "res://Items/Consumables/Juice_Pear/Juice_Pear.tres",
    "Juice Raspberry": "res://Items/Consumables/Juice_Raspberry/Juice_Raspberry.tres",
    "Field Ration (MRE)": "res://Items/Consumables/Field_Ration/Field_Ration.tres",
    "Canned Meat": "res://Items/Consumables/Canned_Meat/Canned_Meat.tres",
    "Canned Meatballs": "res://Items/Consumables/Canned_Meatballs/Canned_Meatballs.tres",
    "Canned Peaches": "res://Items/Consumables/Canned_Peaches/Canned_Peaches.tres",
    "Canned Pear": "res://Items/Consumables/Canned_Pear/Canned_Pear.tres",
    "Canned Peas": "res://Items/Consumables/Canned_Peas/Canned_Peas.tres",
    "Canned Pea Soup": "res://Items/Consumables/Canned_Pea_Soup/Canned_Pea_Soup.tres",
    "Canned Pineapple": "res://Items/Consumables/Canned_Pineapple/Canned_Pineapple.tres",
    "Canned Tomatoes": "res://Items/Consumables/Canned_Tomatoes/Canned_Tomatoes.tres",
    "Canned Tuna": "res://Items/Consumables/Canned_Tuna/Canned_Tuna.tres",
    "Crackers": "res://Items/Consumables/Crackers/Crackers.tres",
    "Energy Powder": "res://Items/Consumables/Energy_Powder/Energy_Powder.tres",
    "Potato": "res://Items/Consumables/Potato/Potato.tres",
    "Mustard": "res://Items/Consumables/Mustard/Mustard.tres",
    "Salty Liquorice": "res://Items/Consumables/Salty_Liquorice/Salty_Liquorice.tres",
    "Peanuts": "res://Items/Consumables/Peanuts/Peanuts.tres",
    "Chocolate War": "res://Items/Consumables/Chocolate_War/Chocolate_War.tres",
    "Coffee": "res://Items/Consumables/Coffee/Coffee.tres",
    "Coffee Brewed": "res://Items/Consumables/Coffee_Brewed/Coffee_Brewed.tres",
    "Sugar": "res://Items/Consumables/Sugar/Sugar.tres",
    "Yeast": "res://Items/Consumables/Yeast/Yeast.tres",
    "Cooked Pea Soup": "res://Items/Consumables/Cooked_Pea_Soup/Cooked_Pea_Soup.tres",
    "Cooked Tomato Soup": "res://Items/Consumables/Cooked_Tomato_Soup/Cooked_Tomato_Soup.tres",
    "Cooked Fish Soup": "res://Items/Consumables/Cooked_Fish_Soup/Cooked_Fish_Soup.tres",
    "Cooked Meatballs": "res://Items/Consumables/Cooked_Meatballs/Cooked_Meatballs.tres",
    "Kompot": "res://Items/Consumables/Kompot/Kompot.tres",
    "Beer": "res://Items/Consumables/Beer/Beer.tres",
    "Kilju": "res://Items/Consumables/Kilju/Kilju.tres",
    "Snus": "res://Items/Consumables/Snus/Snus.tres",
    "Cigars": "res://Items/Consumables/Cigars/Cigars.tres",
    "Cigarettes": "res://Items/Consumables/Cigarettes/Cigarettes.tres",
    "Cat Food": "res://Items/Consumables/Cat_Food/Cat_Food.tres",
    "Fish (Bream)": "res://Items/Fishing/Bream/Bream.tres",
    "Fish (Perch)": "res://Items/Fishing/Perch/Perch.tres",
    "Fish (Pike)": "res://Items/Fishing/Pike/Pike.tres",
    "Fish (Roach)": "res://Items/Fishing/Roach/Roach.tres"
}

const KEYS = {
    "Attic Key": "res://Items/Keys/Key_Attic.tres",
    "Bunker Key": "res://Items/Keys/Key_Bunker.tres",
    "Cellar Key": "res://Items/Keys/Key_Cellar.tres",
    "Classroom Key": "res://Items/Keys/Key_Classroom.tres",
    "Gymnasium Key": "res://Items/Keys/Key_Gymnasium.tres",
    "Tunnel Key": "res://Items/Keys/Key_Tunnel.tres"
}

const FURNITURE = {
    "Freezer": "res://Assets/Freezer/Freezer_F.tres",
    "Military Crate": "res://Assets/Crate_Military/Crate_Military_F.tres",
    "Special Crate": "res://Assets/Crate_Special/Crate_Special_F.tres",
    "Cupboard": "res://Assets/Cupboard/Cupboard_F.tres",
    "Fridge": "res://Assets/Fridge/Fridge_F.tres",
    "Locker": "res://Assets/Locker/Locker_F.tres",
    "Nightstand": "res://Assets/Nightstand/Nightstand_F.tres",
    "Lake Painting": "res://Assets/Painting/Painting_Lake_F.tres",
    "Coat Rack": "res://Assets/Rack_Coat/Rack_Coat_F.tres",
    "Leather Sofa": "res://Assets/Sofa_Leather/Sofa_Leather_F.tres",
    "Medical Cabinet": "res://Assets/Cabinet_Medical/Cabinet_Medical_F.tres",
    "Wood Cabinet": "res://Assets/Cabinet_Wood/Cabinet_Wood_F.tres",
    "Office Cabinet": "res://Assets/Cabinet_Office/Cabinet_Office_F.tres",
    "Padded Stool": "res://Assets/Stool_Padded/Stool_Padded_F.tres",
    "Military Stool": "res://Assets/Stool_Military/Stool_Military_F.tres",
    "Rag Carpet": "res://Assets/Carpet/Carpet_Rag_F.tres",
    "Persian Carpet": "res://Assets/Carpet/Carpet_Persian_F.tres",
    "Rya Maria": "res://Assets/Rya/Rya_Maria_F.tres",
    "Long Curtain": "res://Assets/Curtains/Curtain_Long_F.tres",
    "Mini Curtain": "res://Assets/Curtains/Curtain_Mini_F.tres",
    "Wood Shelf": "res://Assets/Shelf_Wood/Shelf_Wood_F.tres",
    "Wall Shelf": "res://Assets/Shelf_Wall/Shelf_Wall_F.tres",
    "Metal Shelf": "res://Assets/Shelf_Metal/Shelf_Metal_F.tres",
    "Cabin Table": "res://Assets/Table_Cabin/Table_Cabin_F.tres",
    "Canteen Table": "res://Assets/Table_Canteen/Table_Canteen_F.tres",
    "Kitchen Table": "res://Assets/Table_Kitchen/Table_Kitchen_F.tres",
    "Office Table": "res://Assets/Table_Office/Table_Office_F.tres",
    "Stove": "res://Assets/Stove/Stove_F.tres",
    "Civilian Bed": "res://Assets/Bed_Civilian/Bed_Civilian_F.tres",
    "Nomad Bed": "res://Assets/Bed_Nomad/Bed_Nomad_F.tres",
    "Weapon Display": "res://Assets/Weapon_Display/Weapon_Display_F.tres",
    "Office Chair": "res://Assets/Chair_Office/Chair_Office_F.tres",
    "School Chair": "res://Assets/Chair_School/Chair_School_F.tres",
    "Television": "res://Assets/Television/Television_F.tres",
    "Target Stand": "res://Assets/Target_Stand/Target_Stand_F.tres",
    "Border Zone Sign": "res://Assets/Sign_Border_Zone/Sign_Border_Zone_F.tres",
    "Short Trolley": "res://Assets/Trolley/Trolley_Short_F.tres",
    "Tall Trolley": "res://Assets/Trolley/Trolley_Tall_F.tres",
    "Posture Poster": "res://Assets/Posters/Poster_Posture_F.tres",
    "Dartboard": "res://Assets/Dartboard/Dartboard_F.tres",
    "Pallet": "res://Assets/Pallet/Pallet_F.tres"
}

const MISC = {
    # Electronics & Audio
    "Battery (Car)": "res://Items/Electronics/Battery/Battery.tres",
    "Batteries (Small)": "res://Items/Electronics/Batteries/Batteries.tres",
    "Battery Cables": "res://Items/Electronics/Battery_Cables/Battery_Cables.tres",
    "Polaris": "res://Items/Electronics/Polaris/Polaris.tres",
    "Inverter": "res://Items/Electronics/Inverter/Inverter.tres",
    "Hotplate": "res://Items/Electronics/Hotplate/Hotplate.tres",
    "Cooking Station": "res://Items/Electronics/Cooking_Station/Cooking_Station.tres",
    "Coffeemaster": "res://Items/Electronics/Coffeemaster/Coffeemaster.tres",
    "Cassette Player": "res://Items/Electronics/Casette_Player/Casette_Player.tres",
    "Cassette (Electrofolk)": "res://Items/Electronics/Casette_Electrofolk/Casette_Electrofolk.tres",
    "Cassette (Symphony)": "res://Items/Electronics/Casette_Symphony/Casette_Symphony.tres",
    "Cassette (OST)": "res://Items/Electronics/Casette_OST/Casette_OST.tres",
    "Cassette (Radio)": "res://Items/Electronics/Casette_Radio/Casette_Radio.tres",
    "Narva": "res://Items/Electronics/Narva/Narva.tres",
    "Alarm Clock": "res://Items/Electronics/Alarm_Clock/Alarm_Clock.tres",
    
    # Utilities & Tools
    "Toolbox": "res://Items/Misc/Toolbox/Toolbox.tres",
    "Jerry Can": "res://Items/Misc/Jerry_Can/Jerry_Can.tres",
    "Weapon Repair Kit": "res://Items/Misc/Weapon_Repair_Kit/Weapon_Repair_Kit.tres",
    "Duct Tape": "res://Items/Misc/Duct_Tape/Duct_Tape.tres",
    "Nails": "res://Items/Misc/Nails/Nails.tres",
    "Lumber": "res://Items/Misc/Lumber/Lumber.tres",
    "Sticks": "res://Items/Misc/Sticks/Sticks.tres",
    "Matches": "res://Items/Misc/Matches/Matches.tres",
    "Oil Filter": "res://Items/Misc/Oil_Filter/Oil_Filter.tres",
    "Mess Kit": "res://Items/Misc/Mess_Kit/Mess_Kit.tres",
    "Happy Stove": "res://Items/Misc/Happy_Stove/Happy_Stove.tres",
    "Water Lock": "res://Items/Misc/Water_Lock/Water_Lock.tres",
    "Can Empty": "res://Items/Consumables/Can_Empty/Can_Empty.tres",
    
    # Comfort & Survival
    "Sleeping Bag": "res://Items/Misc/Sleeping_Bag/Sleeping_Bag.tres",
    "Mattress": "res://Items/Misc/Mattress/Mattress.tres",
    "Pillow": "res://Items/Misc/Pillow/Pillow.tres",
    "Blanket": "res://Items/Misc/Blanket/Blanket.tres",
    "Toilet Paper": "res://Items/Misc/Toilet_Paper/Toilet_Paper.tres",
    "Bucket": "res://Items/Misc/Bucket/Bucket.tres",
    "Coffee Filter": "res://Items/Misc/Coffee_Filter/Coffee_Filter.tres",
    "Rags": "res://Items/Misc/Rags/Rags.tres",
    "Board Game": "res://Items/Misc/Board_Game/Board_Game.tres",
    
    # Navigation & Intel
    "Map": "res://Items/Misc/Map/Map.tres",
    "Tactical Map": "res://Items/Misc/Map_Tactical/Map_Tactical.tres",
    
    # Books
    "Children's Book": "res://Items/Books/Book_Children.tres",
    "Cooking Book": "res://Items/Books/Book_Cooking.tres",
    "Fishing Book": "res://Items/Books/Book_Fishing.tres",
    "Religion Book": "res://Items/Books/Book_Religion.tres",
    
    # Instruments & Hobbies
    "Guitar": "res://Items/Instruments/Guitar/Guitar.tres",
    "Harmonica": "res://Items/Instruments/Harmonica/Harmonica.tres",
    "Fishing Rod": "res://Items/Fishing/Fishing_Rod/Fishing_Rod.tres",
    "Tackle Box": "res://Items/Misc/Tackle_Box/Tackle_Box.tres",
    
    # Lore
    "Cat": "res://Items/Lore/Cat/Cat.tres",
    "Patient Report": "res://Items/Lore/Patient_Report/Patient_Report.tres",
    "Oil Sample": "res://Items/Lore/Oil_Sample/Oil_Sample.tres"
}
