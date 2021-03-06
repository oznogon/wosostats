# This creates a match stats table for a specified stat, 
# given as "match_stat", broken up into each location zone.
source("https://raw.githubusercontent.com/amj2012/wosostats/master/code/version-2/functions.R")

#Create heat maps for these specific stats:
# 1. Attempted pases (attempted-passes)
# 2. Completed passes (completed-passes)
# 3. Passing completion percentage (pass-comp-pct)
# 4. Interceptions (interceptions)
# 5. Take ons won (take-ons-won)
# 6. Take ons lost (take-ons-lost)
# 7. Aerial duels won (aerial_duels-won)
# 8. Aerial duels lost (aerial-duels-lost)
# 9. Tackles (tackles)
# 10. Pressure/Challenges (pressure)
# 11. Recoveries (recoveries)

#Set the stat you want as "match_stat."
#"match_stat" MUST be written exactly as in the list above in
#the parentheses, and it MUST be one of the eight stats listed.
#For now, haven't yet figured out how to create heat maps for
#other stats.

##FUNCTION TO CREATE STATS TABLE FOR ONE MATCH----------
createLocationStatsTable <- function(match_stat, match_df){
  players <- getPlayers(match_df)
  if(match_stat == "everything") {
    stats_tab <- merge(players, getPassAtt(match_df), by="Player", all=TRUE)
    stats_tab <- merge(stats_tab, getPassComp(match_df), by="Player", all=TRUE)
    stats_tab <- merge(stats_tab, getPassPct(match_df), by="Player", all=TRUE)
    stats_tab <- merge(stats_tab, getInterceptions(match_df), by="Player", all=TRUE)
    stats_tab <- merge(stats_tab, getTakeOnsWon(match_df), by="Player", all=TRUE)
    stats_tab <- merge(stats_tab, getTakeOnsLost(match_df), by="Player", all=TRUE)
    stats_tab <- merge(stats_tab, getAerialsWon(match_df), by="Player", all=TRUE)
    stats_tab <- merge(stats_tab, getAerialsLost(match_df), by="Player", all=TRUE)
    stats_tab <- merge(stats_tab, getTackles(match_df), by="Player", all=TRUE)
    stats_tab <- merge(stats_tab, getPressures(match_df), by="Player", all=TRUE)
    stats_tab <- merge(stats_tab, getRecoveries(match_df), by="Player", all=TRUE)
  } else if (match_stat == "attempted-passes") {
    stats_tab <- merge(players, getPassAtt(match_df), by="Player", all=TRUE)
  } else if (match_stat == "completed-passes") {
    stats_tab <- merge(players, getPassComp(match_df), by="Player", all=TRUE)
  } else if (match_stat == "pass-comp-pct") {
    stats_tab <- merge(players, getPassPct(match_df), by="Player", all=TRUE)
  } else if (match_stat == "interceptions") {
    stats_tab <- merge(players, getInterceptions(match_df), by="Player", all=TRUE)
  } else if (match_stat == "take-ons-won") {
    stats_tab <- merge(players, getTakeOnsWon(match_df), by="Player", all=TRUE)
  } else if (match_stat == "take-ons-lost") {
    stats_tab <- merge(players, getTakeOnsLost(match_df), by="Player", all=TRUE)
  } else if (match_stat == "aerial-duels-won") {
    stats_tab <- merge(players, getAerialsWon(match_df), by="Player", all=TRUE)
  } else if (match_stat == "aerial-duels-lost") {
    stats_tab <- merge(players, getAerialsLost(match_df), by="Player", all=TRUE)
  } else if (match_stat == "tackles") {
    stats_tab <- merge(players, getTackles(match_df), by="Player", all=TRUE)
  } else if (match_stat == "pressure") {
    stats_tab <- merge(players, getPressures(match_df), by="Player", all=TRUE)
  } else if (match_stat == "recoveries") {
    stats_tab <- merge(players, getRecoveries(match_df), by="Player", all=TRUE)
  }
  stats_tab[is.na(stats_tab)] <- 0
  names(stats_tab) <- gsub(" ",".", names(stats_tab))
  stats_tab
}

##FUNCTION TO CREATE MULTIPLE STATS TABLES FOR VARIOUS MATCHES---------
createMultiLocStatsTabs <- function(match_list, match_stat) {
  stats_list <- vector("list", 0)
  #For every match csv file in match_list, create a stats table
  for (matchSheet in match_list){
    stats_tab <- createLocationStatsTable(match_stat, matchSheet)
    stats_list[[length(stats_list)+1]] <- stats_tab
  }
  stats_list
}

##CREATES CSV FILE FOR STATS TABLE---------
writeFiles <- function(stats_list, match_names, match_stat) {
  for (i in 1:length(stats_list)) {
    file_name <- paste0(match_names[i],"-",match_stat,".csv")
    write.csv(stats_list[[i]], file=file_name, row.names = FALSE)
  }
}

##CREATE COLUMNS WITH PLAYER INFO---------
#Here, we create a data frame for the "poss.player" column, and another for the
#"def.player" column. Then, we merge them into one, which is the beginning of the
#stats table, which for now will just be called "players"
getPlayers <- function(match_df) {
  players <- rbind(data.frame(Player=unique(match_df$poss.player), Team=NA, GP=NA, MP=NA, GS=NA),
                   data.frame(Player=unique(match_df$def.player), Team=NA, GP=NA, MP=NA, GS=NA))
  players <- players[!is.na(players[,"Player"]),]
  players <- unique(players[,])
  #Here, we use the match_df data frame (this is the larger match spreadsheet you created with
  #tidy-excel.R) to fill data in the "players" data frame such as each player's team
  #and how many minutes they played.
  matchlength <- length(unique(match_df$time))
  substitutions <- match_df[grepl("substitution",match_df[,"poss.action"]),]
  stats.tab.row <- 1
  while (stats.tab.row <= nrow(players)) {
    player <- as.character(players[stats.tab.row,"Player"])
    #if they don't appear in the substitutions data frame, the player played the entire match
    if (nrow(substitutions[substitutions[,"poss.player"] %in% player,]) == 0) {
      players[stats.tab.row,"GP"] <- 1
      players[stats.tab.row,"MP"] <- matchlength
      players[stats.tab.row,"GS"] <- 1
    } else if (nrow(substitutions[substitutions[,"poss.player"] %in% player,]) > 0) {
      #check if she was a starter, based on if she was only ever substituted on
      if (grepl("substitution.on", paste(substitutions[substitutions[,"poss.player"] == player,"poss.action"],collapse="|"))==FALSE) {
        #if she was a starter who was subbed off, get the length of unique values for vector match_df[,"time] 
        #up to where she got subbed off
        eventnum <- substitutions[substitutions[,"poss.player"] == player,"event"]
        lastminute <- grep(eventnum, match_df[,"event"])
        minutesplayed <- length(unique(match_df[1:lastminute,"time"]))
        players[stats.tab.row,"GP"] <- 1
        players[stats.tab.row,"MP"] <- minutesplayed
        players[stats.tab.row,"GS"] <- 1
      } else
        #if she wasn't a starter and got subbed on and wasn't also later subbed off
        if ((grepl("substitution.on", paste(substitutions[substitutions[,"poss.player"] == player,"poss.action"],collapse="|"))==TRUE)
            & (grepl("substitution.off", paste(substitutions[substitutions[,"poss.player"] == player,"poss.action"],collapse="|"))==FALSE)) {
          #if she wasn't a starter, got subbed on, and was never subbed off, get the length of unique
          #values for vector match_df[,"time] from when she got subbed on to when she got subbed off
          eventnum <- substitutions[substitutions[,"poss.player"] == player,"event"]
          firstminute <- grep(eventnum, match_df[,"event"])[1]
          minutesplayed <- length(unique(match_df[firstminute:nrow(match_df),"time"]))
          players[stats.tab.row,"GP"] <- 1
          players[stats.tab.row,"MP"] <- minutesplayed
          players[stats.tab.row,"GS"] <- 0
        } else
          #if she wasn't a starter, got subbed on, and was later subbed off
          if ((grepl("substitution.on", paste(substitutions[substitutions[,"poss.player"] == player,"poss.action"],collapse="|"))==TRUE)
              & (grepl("substitution.off", paste(substitutions[substitutions[,"poss.player"] == player,"poss.action"],collapse="|"))==TRUE)) {
            #if she wasn't a starter, got subbed on, and as later subbed off, get the length of unique
            #values for vector match_df[,"time] from when she got subbed on to when she got subbed off
            eventnum <- substitutions[substitutions[,"poss.player"] == player,"event"]
            firstminute <- grep(eventnum[1], match_df[,"event"])
            lastminute <- grep(eventnum[2], match_df[,"event"])
            minutesplayed <- length(unique(match_df[firstminute:lastminute,"time"]))
            players[stats.tab.row,"GP"] <- 1
            players[stats.tab.row,"MP"] <- minutesplayed
            players[stats.tab.row,"GS"] <- 0
          }
    }
    stats.tab.row <- stats.tab.row + 1
  }
  stats.tab.row <- 1
  while (stats.tab.row <= nrow(players)) {
    player <- as.character(players[stats.tab.row,"Player"])
    playerteam <- unique(match_df[match_df[,"poss.player"] == player & !is.na(match_df[,"poss.player"]),"poss.team"])
    if(length(playerteam) == 0) {
      playerteam <- unique(match_df[match_df[,"def.player"] == player & !is.na(match_df[,"def.player"]),"def.team"])
    }
    players[stats.tab.row,"Team"] <- playerteam
    stats.tab.row <- stats.tab.row + 1
  }
  rm(eventnum,matchlength,player, playerteam, stats.tab.row, firstminute, 
     lastminute, minutesplayed, substitutions)
  players
}

##CREATE COLUMNS FOR ATTEMPTED OPEN PLAY PASSES BY ZONE--------
getPassAtt <- function(match_df){
  #Passing stats, without dead ball scenarios (GKs, GK throws, GK drop kicks,FKs, CKs, throw ins)
  t <- addColumnForQualifier("opPass", pattern="throw|gk|corner.kick|free.kick|goal.kick", patternLocation = "play.type", ogdf = match_df, invert = TRUE,
                             ndf = createCleanDataFrame(c("passes.f.c", "passes.f", 
                                                          "passes.s.c", "passes.s", "passes.b.c", "passes.b"), "poss.action", match_df))
  t <- t[t[,"opPass"]=="yes",]
  #creates column for each zone
  t <- addMultiColumnsForQualifiers(patterns = c("D6"="D6", "D18"="D18", "DL"="D3L|DL", "DC"="D3C|DC","DR"="D3R|DR", 
                                                 "DML"="DM3L|DML", "DMC"="DM3C|DMC", "DMR"="DM3R|DMR", "AML"="AM3L|AML",
                                                 "AMC"="AM3C|AMC", "AMR"="AM3R|AMR", "AL"="A3L|AL", "AC"="A3C|AC", "AR"="A3R|AR",
                                                 "A18"="A18", "A6"="A6"),
                                    ogdf = match_df,ndf = t,
                                    pattern_locations = c("poss.location","poss.location","poss.location","poss.location",
                                                          "poss.location","poss.location","poss.location", "poss.location",
                                                          "poss.location","poss.location","poss.location","poss.location",
                                                          "poss.location","poss.location","poss.location","poss.location"))
  ##Creates blank table with columns for direction distribution
  zones <- c("D6", "D18", "DL", "DC","DR", "DML", "DMC", "DMR", "AML",
             "AMC", "AMR", "AL", "AC", "AR", "A18", "A6")
  for(i in zones) {
    tab <- createPassingTable(t[t[,i] == "yes",])
    names(tab) <- c("Player", paste0(i,".opPass.Comp"), paste0(i,".opPass.Att"), paste0(i,".opPass.Comp.Pct"))
    tab <- tab[,grep("Comp",names(tab), invert = TRUE)]
    if(exists("passAttLocation")){
      passAttLocation <- merge(passAttLocation, tab, by="Player", all=TRUE)
    } else {
      passAttLocation <- tab
    }
  }
  passAttLocation
  #rm(t, tab, zones, passAttLocation)
}

##CREATE COLUMNS FOR COMPLETED OPEN PLAY PASSES BY ZONE--------
getPassComp <- function(match_df) {
  #Passing stats, without dead ball scenarios (GKs, GK throws, GK drop kicks,FKs, CKs, throw ins)
  t <- addColumnForQualifier("opPass", pattern="throw|gk|corner.kick|free.kick|goal.kick", patternLocation = "play.type", ogdf = match_df, invert = TRUE,
                             ndf = createCleanDataFrame(c("passes.f.c", "passes.f", 
                                                          "passes.s.c", "passes.s", "passes.b.c", "passes.b"), "poss.action", match_df))
  t <- t[t[,"opPass"]=="yes",]
  #creates column for each zone
  t <- addMultiColumnsForQualifiers(patterns = c("D6"="D6", "D18"="D18", "DL"="D3L|DL", "DC"="D3C|DC","DR"="D3R|DR", 
                                                 "DML"="DM3L|DML", "DMC"="DM3C|DMC", "DMR"="DM3R|DMR", "AML"="AM3L|AML",
                                                 "AMC"="AM3C|AMC", "AMR"="AM3R|AMR", "AL"="A3L|AL", "AC"="A3C|AC", "AR"="A3R|AR",
                                                 "A18"="A18", "A6"="A6"),
                                    ogdf = match_df,ndf = t,
                                    pattern_locations = c("poss.location","poss.location","poss.location","poss.location",
                                                          "poss.location","poss.location","poss.location", "poss.location",
                                                          "poss.location","poss.location","poss.location","poss.location",
                                                          "poss.location","poss.location","poss.location","poss.location"))
  ##Creates blank table with columns for direction distribution
  zones <- c("D6", "D18", "DL", "DC","DR", "DML", "DMC", "DMR", "AML",
             "AMC", "AMR", "AL", "AC", "AR", "A18", "A6")
  for(i in zones) {
    tab <- createPassingTable(t[t[,i] == "yes",])
    names(tab) <- c("Player", paste0(i,".opPass.Comp"), paste0(i,".opPass.Att"), paste0(i,".opPass.Comp.Pct"))
    tab <- tab[,grep("Att",names(tab), invert = TRUE)]
    tab <- tab[,grep("Pct",names(tab), invert = TRUE)]
    if(exists("passCompLocation")){
      passCompLocation <- merge(passCompLocation, tab, by="Player", all=TRUE)
    } else {
      passCompLocation <- tab
    }
  }
  passCompLocation
}

##CREATE COLUMNS FOR OPEN PLAY PASSING COMP PCT BY ZONE--------
getPassPct <- function(match_df) {
  #Passing stats, without dead ball scenarios (GKs, GK throws, GK drop kicks,FKs, CKs, throw ins)
  t <- addColumnForQualifier("opPass", pattern="throw|gk|corner.kick|free.kick|goal.kick", patternLocation = "play.type", ogdf = match_df, invert = TRUE,
                             ndf = createCleanDataFrame(c("passes.f.c", "passes.f", 
                                                          "passes.s.c", "passes.s", "passes.b.c", "passes.b"), "poss.action", match_df))
  t <- t[t[,"opPass"]=="yes",]
  #creates column for each zone
  t <- addMultiColumnsForQualifiers(patterns = c("D6"="D6", "D18"="D18", "DL"="D3L|DL", "DC"="D3C|DC","DR"="D3R|DR", 
                                                 "DML"="DM3L|DML", "DMC"="DM3C|DMC", "DMR"="DM3R|DMR", "AML"="AM3L|AML",
                                                 "AMC"="AM3C|AMC", "AMR"="AM3R|AMR", "AL"="A3L|AL", "AC"="A3C|AC", "AR"="A3R|AR",
                                                 "A18"="A18", "A6"="A6"),
                                    ogdf = match_df,ndf = t,
                                    pattern_locations = c("poss.location","poss.location","poss.location","poss.location",
                                                          "poss.location","poss.location","poss.location", "poss.location",
                                                          "poss.location","poss.location","poss.location","poss.location",
                                                          "poss.location","poss.location","poss.location","poss.location"))
  ##Creates blank table with columns for direction distribution
  zones <- c("D6", "D18", "DL", "DC","DR", "DML", "DMC", "DMR", "AML",
             "AMC", "AMR", "AL", "AC", "AR", "A18", "A6")
  for(i in zones) {
    tab <- createPassingTable(t[t[,i] == "yes",])
    names(tab) <- c("Player", paste0(i,".opPass.Comp"), paste0(i,".opPass.Att"), paste0(i,".opPass.Pct"))
    tab <- tab[,grep("Att",names(tab), invert = TRUE)]
    tab <- tab[,grep("Comp",names(tab), invert = TRUE)]
    if(exists("passPctLocation")){
      passPctLocation <- merge(passPctLocation, tab, by="Player", all=TRUE)
    } else {
      passPctLocation <- tab
    }
  }
  passPctLocation
}
  

##CREATE COLUMNS FOR INTERCEPTIONS BY ZONE--------
getInterceptions <- function(match_df) {
  t <- createDataFrame(c("interceptions"), "def.action", match_df)
  t <- t[,c("event","time", "def.position","def.team","def.player","def.action","def.location", "def.player.disciplinary","def.notes")]
  names(t) <- c("event", "time", "position","team", "poss.player", "player.event", "location", 
                "def.player.disciplinary", "def.notes")
  t <- t[t[,"player.event"]=="interceptions" & !is.na(t[,"player.event"]),]
  t <- addMultiColumnsForQualifiers(patterns = c("D6"="D6", "D18"="D18", "DL"="D3L|DL", "DC"="D3C|DC","DR"="D3R|DR", 
                                                 "DML"="DM3L|DML", "DMC"="DM3C|DMC", "DMR"="DM3R|DMR", "AML"="AM3L|AML",
                                                 "AMC"="AM3C|AMC", "AMR"="AM3R|AMR", "AL"="A3L|AL", "AC"="A3C|AC", "AR"="A3R|AR",
                                                 "A18"="A18", "A6"="A6"),
                                    ogdf = t,ndf = t,
                                    pattern_locations = c("location","location","location","location",
                                                          "location","location","location", "location",
                                                          "location","location","location","location",
                                                          "location","location","location","location"))
  ##Creates blank table with columns for direction distribution
  zones <- c("D6", "D18", "DL", "DC","DR", "DML", "DMC", "DMR", "AML",
             "AMC", "AMR", "AL", "AC", "AR", "A18", "A6")
  for(i in zones) {
    tab <- createTable(c("interceptions"), "player.event", t[t[,i] == "yes",])
    names(tab) <- c("Player", paste0(i,".Int"))
    if(exists("intLocation")){
      intLocation <- merge(intLocation, tab, by="Player", all=TRUE)
    } else {
      intLocation <- tab
    }
  }
  intLocation
}

##CREATE COLUMNS FOR TAKE ONS WON BY ZONE--------
getTakeOnsWon <- function(match_df) {
  t <- createCleanDataFrame(c("take.on.won"),"poss.action", match_df)
  t <- addMultiColumnsForQualifiers(patterns = c("D6"="D6", "D18"="D18", "DL"="D3L|DL", "DC"="D3C|DC","DR"="D3R|DR", 
                                                 "DML"="DM3L|DML", "DMC"="DM3C|DMC", "DMR"="DM3R|DMR", "AML"="AM3L|AML",
                                                 "AMC"="AM3C|AMC", "AMR"="AM3R|AMR", "AL"="A3L|AL", "AC"="A3C|AC", "AR"="A3R|AR",
                                                 "A18"="A18", "A6"="A6"),
                                    ogdf = match_df,ndf = t,
                                    pattern_locations = c("poss.location","poss.location","poss.location","poss.location",
                                                          "poss.location","poss.location","poss.location", "poss.location",
                                                          "poss.location","poss.location","poss.location","poss.location",
                                                          "poss.location","poss.location","poss.location","poss.location"))
  zones <- c("D6", "D18", "DL", "DC","DR", "DML", "DMC", "DMR", "AML",
             "AMC", "AMR", "AL", "AC", "AR", "A18", "A6")
  for(i in zones) {
    tab <- createTable(c("take.on.won"), "poss.action", t[t[,i] == "yes",])
    names(tab) <- c("Player", paste0(i,".TO.Won"))
    if(exists("takeOnWonLocation")){
      takeOnWonLocation <- merge(takeOnWonLocation, tab, by="Player", all=TRUE)
    } else {
      takeOnWonLocation <- tab
    }
  }
  takeOnWonLocation
}

##CREATE COLUMNS FOR TAKE ONS LOST BY ZONE--------
getTakeOnsLost <- function(match_df) {
  t <- createCleanDataFrame(c("take.on.lost"),"poss.action", match_df)
  t <- addMultiColumnsForQualifiers(patterns = c("D6"="D6", "D18"="D18", "DL"="D3L|DL", "DC"="D3C|DC","DR"="D3R|DR", 
                                                 "DML"="DM3L|DML", "DMC"="DM3C|DMC", "DMR"="DM3R|DMR", "AML"="AM3L|AML",
                                                 "AMC"="AM3C|AMC", "AMR"="AM3R|AMR", "AL"="A3L|AL", "AC"="A3C|AC", "AR"="A3R|AR",
                                                 "A18"="A18", "A6"="A6"),
                                    ogdf = match_df,ndf = t,
                                    pattern_locations = c("poss.location","poss.location","poss.location","poss.location",
                                                          "poss.location","poss.location","poss.location", "poss.location",
                                                          "poss.location","poss.location","poss.location","poss.location",
                                                          "poss.location","poss.location","poss.location","poss.location"))
  zones <- c("D6", "D18", "DL", "DC","DR", "DML", "DMC", "DMR", "AML",
             "AMC", "AMR", "AL", "AC", "AR", "A18", "A6")
  for(i in zones) {
    tab <- createTable(c("take.on.lost"), "poss.action", t[t[,i] == "yes",])
    names(tab) <- c("Player", paste0(i,".TO.Lost"))
    if(exists("takeOnLostLocation")){
      takeOnLostLocation <- merge(takeOnLostLocation, tab, by="Player", all=TRUE)
    } else {
      takeOnLostLocation <- tab
    }
  }
  takeOnLostLocation
}

##CREATE COLUMNS FOR AERIAL DUELS WON BY ZONE--------
getAerialsWon <- function(match_df) {
  t <- createDataFrame(c("aerial.won", "aerial.lost"), "poss.action", match_df)
  t2 <- t[,c("event", "time", "poss.position", "poss.team", "poss.player", "poss.action", "poss.location")]
  names(t2) <- c("event", "time", "position", "team", "poss.player", "player.event", "location")
  t3 <- t[,c("event", "time","def.position", "def.team", "def.player", "def.action", "def.location")]
  names(t3) <- c("event", "time", "position", "team", "poss.player", "player.event", "location")
  t4 <- rbind(t2,t3)
  t4 <- t4[grep("aerial.won",t4[,"player.event"]),]
  t4 <- addMultiColumnsForQualifiers(patterns = c("D6"="D6", "D18"="D18", "DL"="D3L|DL", "DC"="D3C|DC","DR"="D3R|DR", 
                                                 "DML"="DM3L|DML", "DMC"="DM3C|DMC", "DMR"="DM3R|DMR", "AML"="AM3L|AML",
                                                 "AMC"="AM3C|AMC", "AMR"="AM3R|AMR", "AL"="A3L|AL", "AC"="A3C|AC", "AR"="A3R|AR",
                                                 "A18"="A18", "A6"="A6"),
                                    ogdf = t4,ndf = t4,
                                    pattern_locations = c("location","location","location","location",
                                                          "location","location","location", "location",
                                                          "location","location","location","location",
                                                          "location","location","location","location"))
  zones <- c("D6", "D18", "DL", "DC","DR", "DML", "DMC", "DMR", "AML",
             "AMC", "AMR", "AL", "AC", "AR", "A18", "A6")
  for(i in zones) {
    tab <- createTable(c("aerial.won"), "player.event", t4[t4[,i] == "yes",])
    names(tab) <- c("Player", paste0(i,".AD.Won"))
    if(exists("aerialWonLocation")){
      aerialWonLocation <- merge(aerialWonLocation, tab, by="Player", all=TRUE)
    } else {
      aerialWonLocation <- tab
    }
  }
  aerialWonLocation
}

##CREATE COLUMNS FOR AERIAL DUELS LOST BY ZONE--------
getAerialsLost <- function(match_df) {
  t <- createDataFrame(c("aerial.won", "aerial.lost"), "poss.action", match_df)
  t2 <- t[,c("event", "time", "poss.position", "poss.team", "poss.player", "poss.action", "poss.location")]
  names(t2) <- c("event", "time", "position", "team", "poss.player", "player.event", "location")
  t3 <- t[,c("event", "time","def.position", "def.team", "def.player", "def.action", "def.location")]
  names(t3) <- c("event", "time", "position", "team", "poss.player", "player.event", "location")
  t4 <- rbind(t2,t3)
  t4 <- t4[grep("aerial.lost",t4[,"player.event"]),]
  t4 <- addMultiColumnsForQualifiers(patterns = c("D6"="D6", "D18"="D18", "DL"="D3L|DL", "DC"="D3C|DC","DR"="D3R|DR", 
                                                  "DML"="DM3L|DML", "DMC"="DM3C|DMC", "DMR"="DM3R|DMR", "AML"="AM3L|AML",
                                                  "AMC"="AM3C|AMC", "AMR"="AM3R|AMR", "AL"="A3L|AL", "AC"="A3C|AC", "AR"="A3R|AR",
                                                  "A18"="A18", "A6"="A6"),
                                     ogdf = t4,ndf = t4,
                                     pattern_locations = c("location","location","location","location",
                                                           "location","location","location", "location",
                                                           "location","location","location","location",
                                                           "location","location","location","location"))
  zones <- c("D6", "D18", "DL", "DC","DR", "DML", "DMC", "DMR", "AML",
             "AMC", "AMR", "AL", "AC", "AR", "A18", "A6")
  for(i in zones) {
    tab <- createTable(c("aerial.lost"), "player.event", t4[t4[,i] == "yes",])
    names(tab) <- c("Player", paste0(i,".AD.Lost"))
    if(exists("aerialLostLocation")){
      aerialLostLocation <- merge(aerialLostLocation, tab, by="Player", all=TRUE)
    } else {
      aerialLostLocation <- tab
    }
  }
  aerialLostLocation
}

##CREATE COLUMNS FOR TACKLES BY ZONE--------
getTackles <- function(match_df) {
  t <- createDataFrame(c("tackles.ball.away", "tackles.ball.won", "tackles.ball"), "def.action", match_df)
  t <- t[,c("event","time","def.position","def.team","def.player","def.action","def.location","def.player.disciplinary","def.notes")]
  names(t) <- c("event", "time", "position" ,"team", "poss.player", "player.event", "location", 
                "def.player.disciplinary", "def.notes")
  t <- t[grepl("tackles", t[,"player.event"]) & !is.na(t[,"player.event"]),]
  t <- addMultiColumnsForQualifiers(patterns = c("D6"="D6", "D18"="D18", "DL"="D3L|DL", "DC"="D3C|DC","DR"="D3R|DR", 
                                                 "DML"="DM3L|DML", "DMC"="DM3C|DMC", "DMR"="DM3R|DMR", "AML"="AM3L|AML",
                                                 "AMC"="AM3C|AMC", "AMR"="AM3R|AMR", "AL"="A3L|AL", "AC"="A3C|AC", "AR"="A3R|AR",
                                                 "A18"="A18", "A6"="A6"),
                                    ogdf = t,ndf = t,
                                    pattern_locations = c("location","location","location","location",
                                                          "location","location","location", "location",
                                                          "location","location","location","location",
                                                          "location","location","location","location"))
  ##Creates blank table with columns for direction distribution
  zones <- c("D6", "D18", "DL", "DC","DR", "DML", "DMC", "DMR", "AML",
             "AMC", "AMR", "AL", "AC", "AR", "A18", "A6")
  for(i in zones) {
    tab <- createTable(c("tackles","tackles.ball.away", "tackles.ball.won", "tackles.ball"), "player.event", t[t[,i] == "yes",])
    tab$tackles <- tab$tackles.ball.away + tab$tackles.ball.won + tab$tackles.ball
    tab <- tab[,!(names(tab) %in% c("tackles.ball.away", "tackles.ball.won", "tackles.ball"))]
    names(tab) <- c("Player", paste0(i,".Tackles"))
    if(exists("tackleLocation")){
      tackleLocation <- merge(tackleLocation, tab, by="Player", all=TRUE)
    } else {
      tackleLocation <- tab
    }
  }
  tackleLocation
}

##CREATE COLUMNS FOR PRESSURE BY ZONE--------
getPressures <- function(match_df) {
  t <- createDataFrame(c("pressured", "challenged"), "def.action", match_df)
  t <- t[,c("event","time","def.position","def.team","def.player","def.action","def.location","def.player.disciplinary","def.notes")]
  names(t) <- c("event", "time", "position" ,"team", "poss.player", "player.event", "location", 
                "def.player.disciplinary", "def.notes")
  t <- t[grepl("pressured|challenged", t[,"player.event"]) & !is.na(t[,"player.event"]),]
  t <- addMultiColumnsForQualifiers(patterns = c("D6"="D6", "D18"="D18", "DL"="D3L|DL", "DC"="D3C|DC","DR"="D3R|DR", 
                                                 "DML"="DM3L|DML", "DMC"="DM3C|DMC", "DMR"="DM3R|DMR", "AML"="AM3L|AML",
                                                 "AMC"="AM3C|AMC", "AMR"="AM3R|AMR", "AL"="A3L|AL", "AC"="A3C|AC", "AR"="A3R|AR",
                                                 "A18"="A18", "A6"="A6"),
                                    ogdf = t,ndf = t,
                                    pattern_locations = c("location","location","location","location",
                                                          "location","location","location", "location",
                                                          "location","location","location","location",
                                                          "location","location","location","location"))
  ##Creates blank table with columns for direction distribution
  zones <- c("D6", "D18", "DL", "DC","DR", "DML", "DMC", "DMR", "AML",
             "AMC", "AMR", "AL", "AC", "AR", "A18", "A6")
  for(i in zones) {
    tab <- createTable(c("pressure","pressured", "challenged"), "player.event", t[t[,i] == "yes",])
    tab$pressure <- tab$pressured + tab$challenged
    tab <- tab[,!(names(tab) %in% c("pressured", "challenged"))]
    names(tab) <- c("Player", paste0(i,".Pressure"))
    if(exists("pressureLocation")){
      pressureLocation <- merge(pressureLocation, tab, by="Player", all=TRUE)
    } else {
      pressureLocation <- tab
    }
  }
  pressureLocation
}

##CREATE COLUMNS FOR RECOVERIES BY ZONE--------
getRecoveries <- function(match_df) {
  t <- createCleanDataFrame(c("recoveries"),"poss.action", match_df)
  t <- addMultiColumnsForQualifiers(patterns = c("D6"="D6", "D18"="D18", "DL"="D3L|DL", "DC"="D3C|DC","DR"="D3R|DR", 
                                                 "DML"="DM3L|DML", "DMC"="DM3C|DMC", "DMR"="DM3R|DMR", "AML"="AM3L|AML",
                                                 "AMC"="AM3C|AMC", "AMR"="AM3R|AMR", "AL"="A3L|AL", "AC"="A3C|AC", "AR"="A3R|AR",
                                                 "A18"="A18", "A6"="A6"),
                                    ogdf = match_df,ndf = t,
                                    pattern_locations = c("poss.location","poss.location","poss.location","poss.location",
                                                          "poss.location","poss.location","poss.location", "poss.location",
                                                          "poss.location","poss.location","poss.location","poss.location",
                                                          "poss.location","poss.location","poss.location","poss.location"))
  zones <- c("D6", "D18", "DL", "DC","DR", "DML", "DMC", "DMR", "AML",
             "AMC", "AMR", "AL", "AC", "AR", "A18", "A6")
  for(i in zones) {
    tab <- createTable(c("recoveries"), "poss.action", t[t[,i] == "yes",])
    names(tab) <- c("Player", paste0(i,".Recoveries"))
    if(exists("recoveryLocation")){
      recoveryLocation <- merge(recoveryLocation, tab, by="Player", all=TRUE)
    } else {
      recoveryLocation <- tab
    }
  }
  recoveryLocation
}
