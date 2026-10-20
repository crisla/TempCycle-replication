* Other, older temporary contracts:
replace state = "T" if tyco>=4&tyco<8
replace state = "T" if tyco>=14&tyco<18
replace state = "T" if tyco==22|(tyco>=24&tyco<28)
replace state = "T" if tyco>=34&tyco<39
replace state = "T" if tyco>=53&tyco<59
replace state = "T" if tyco==64|(tyco>=66&tyco<69)
replace state = "T" if tyco>=72&tyco<100
* Other, older permanet contracts:
replace state = "P" if tyco==18
replace state = "P" if tyco>0&tyco<4
replace state = "P" if tyco>10&tyco<14
replace state = "P" if tyco==20|tyco==23
replace state = "P" if tyco>=28&tyco<34
replace state = "P" if tyco>=39&tyco<53
replace state = "P" if tyco>=59&tyco<64
replace state = "P" if tyco==65
replace state = "P" if tyco>=69&tyco<72
