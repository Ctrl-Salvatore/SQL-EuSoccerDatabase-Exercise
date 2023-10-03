/*European Soccer Database, a collection of four individual CSV files, containing: 

leagues.csv
match.csv
player.csv 
match.csv */


#Date difference beetween the oldest and most recent match, to understand timespan
SELECT date_diff(max(date),min(date),day) FROM `match` 
#we have a timespan of 2868 days

/*Now roduce a table which, for each Season and League Name, shows the following statistics about the home goals scored: 
min
average 
mid-range 
max 
sum
*/

SELECT
  season,
  name,
  MIN(home_team_goal) AS min_team_goal,
  AVG(home_team_goal) AS avg_team_goal,
  (MAX(home_team_goal)+Min(home_team_goal))/2 as midrange_team_goal,
  MAX(home_team_goal) AS max_team_goal,
  SUM(home_team_goal) AS total_team_goal
FROM
  `match` AS a
LEFT JOIN
  `leagues` AS b
ON
  a.league_id = b.id
GROUP BY
  Season,
  name
ORDER BY
 total_team_goal DESC

#we can see from this query that the top Season-League is the 2009/2010 England Premier League with 645 goals


/* now we discover how many unique seasons there are in the Match table. 
and then we write a query that shows, for each Season, the number of matches played by each League. */
SELECT
  season, name, count(*) as n_match
FROM
  `match` AS a
LEFT JOIN
  `leagues` AS b
ON
  a.league_id = b.id
Group by
1, 2

/*We can notice there are 8 different season for league, and we can also notice that in the season 2013/2014 
of the Belgium Jupiler League only 12 match have been played


Using Players as the starting point, let's create a new table (PlayerBMI) in which we add: 
a new variable that represents the players weight in kg (mass value divided by 2.205) and call it kg_weight; 
a variable that represents the height in metres (cm divided by 100) and call it m_height; 
a variable that shows the body mass index (BMI) of the player;
Than we filter the table to show only the players with an optimal BMI (from 18.5 to 24.9). 
 */

CREATE TABLE
  Final_Exercise.PlayerBMI AS (
  SELECT
    *,
    weight/2.205 AS kg_weight,
    height/100 AS m_height,
    (weight/2.205)/POW(Height/100,2) AS BMI
  FROM
    `player`
  WHERE
    (weight/2.205)/POW(Height/100,2) BETWEEN 18.5 AND 24.9)

#we can see that there are 10197 lines in this table, but how many players do not have an optimal BMI? 
SELECT count(*) FROM `player`
Where (weight/2.205)/POW(Height/100,2) NOT BETWEEN 18.5 AND 24.9

#863 (we can anwser to this question also subtracting the first table and the second one)


#Let's anwser to other questions, for example: which Team has scored the highest total number of goals (home + away) during the most recent available season? How many goals has it scored? 
with home_goal as(SELECT team_long_name, home_team_api_id, sum(home_team_goal) as tot_home_goal
FROM `match` as A
JOIN `team` as B
ON team_api_id=home_team_api_id
Where season="2015/2016"
Group by 1,2),
away_goal as(SELECT away_team_api_id, sum(away_team_goal) as tot_away_goal
FROM `match` as A
JOIN `team` as B
ON team_api_id=away_team_api_id
Where season="2015/2016"
Group by 1)
select  team_long_name, tot_home_goal + tot_away_goal as Total_goal
from home_goal
join away_goal
ON away_team_api_id=home_team_api_id
order by 2 DESC

#Barcellona, 112 Goals

#Now we create a query that, for each season, shows the name of the team that ranks first in terms of total goals scored. 

WITH home_goal as(
  SELECT 
    season, 
    team_long_name, 
    home_team_api_id, 
    sum(home_team_goal) as tot_home_goal
  FROM `match` as A
  JOIN `team` as B
  ON team_api_id=home_team_api_id
  Group by 1,2,3
),
away_goal as(
  SELECT 
    season, 
    away_team_api_id, 
    sum(away_team_goal) as tot_away_goal
  FROM `match` as A
  JOIN `team` as B
  ON team_api_id=away_team_api_id
  Group by 1,2
), tot_goal as (
SELECT 
  home_goal.season,
  team_long_name,
  (tot_home_goal + tot_away_goal) as Total_goal,
FROM home_goal
JOIN away_goal
ON away_team_api_id=home_team_api_id AND home_goal.season=away_goal.season
ORDER BY season DESC, Total_goal DESC), 
ranking as(
select *, rank() over (partition by season order by total_goal desc) as ranking from tot_goal)
select season, team_long_name, Total_goal from ranking 
Where ranking.ranking=1
Order by season



#From the query above we can also create a new table containing the top 10 teams in terms of total goals scored. 

create Table Final_Exercise.TopScorer as with home_goal as(SELECT team_api_id, team_long_name, home_team_api_id, sum(home_team_goal) as tot_home_goal
FROM `match` as A
JOIN `team` as B
ON team_api_id=home_team_api_id
Group by 1,2,3),
away_goal as(SELECT away_team_api_id, sum(away_team_goal) as tot_away_goal
FROM `match` as A
JOIN `team` as B
ON team_api_id=away_team_api_id
Group by 1) 
select team_api_id, team_long_name, tot_home_goal + tot_away_goal as Total_goal
from home_goal
join away_goal
ON away_team_api_id=home_team_api_id
order by 3 DESC
limit 10

 #We can see that Real Madrid placed first 4 times, Barcellona 3 and Ajax 1

#then here we write a query that shows all the possible "pair combinations" between those 10 teams. 

SELECT a.team_long_name as home_team, b.team_long_name as away_team FROM `TopScorer` a
Inner Join  `TopScorer` b
on a.team_api_id <> b.team_api_id

# There are 90 combination considering homw and away match, we can also make possible to show every combination just once 
# changing “<>” with “<”, in that case we will have 45 combinations