--creates a table for worldcup games
create table worldcup
(match_date date,home_team nvarchar(100),away_team nvarchar(100),
home_score int,away_score int,
city nvarchar(100),country nvarchar(100),neutral varchar(10)
)

--inserting only world cup games from the original dataset into the new table
insert into worldcup
select match_date,home_team,away_team,home_score,away_score,city,country,neutral
from football_data
where tournament_type='fifa world cup'

--Returns the host nations and year of every worldcup
select distinct year(match_date) as worldcup_year, 
country+' '+right(year(match_date),2) as tournaments
from worldcup
order by 1

--Returns the number of games each team has won
select distinct Team,count(Team) as No_of_wins
from(
select match_date,home_team,away_team,home_score,away_score, case
	when home_score>away_score then home_team
	when away_score>home_score then away_team
	else 'Draw' end as Team
from worldcup
group by match_date,home_team,away_team,home_score,away_score
) as No_of_wins
where team<>'Draw'
group by team
order by No_of_wins desc

--Counting the number of games each country has played
select distinct home_team as Team,sum(Number_of_app) as Number_of_games_played
from(
select distinct home_team,count(home_team) as Number_of_app--selects the number of games each team in the 'home' column plays
from worldcup
group by home_team
union all--combines the output from both statements
select distinct away_team,count(away_team) as Number_of_app--selects the number of games each team in the 'away' column plays
from worldcup
group by away_team
) as Numberofgames
group by home_team
order by Number_of_games_played desc

--creating two temporary tables to find the win percentage at the world cup
create table #wins
(Team nvarchar(100), Wins decimal(7,2))
create table #gamesplayed
(Team nvarchar(100), Games_played decimal(7,2))

--Inserting values into wins table
insert into #wins
select distinct Team,count(Team) as No_of_wins
from(
select match_date,home_team,away_team,home_score,away_score, case
	when home_score>away_score then home_team
	when away_score>home_score then away_team
	else 'Draw' end as Team
from worldcup
group by match_date,home_team,away_team,home_score,away_score
) as No_of_wins
where team<>'Draw'
group by team
order by No_of_wins desc

--Inserting values into gamesplayed table
insert into #gamesplayed
select distinct home_team as Team,sum(Number_of_app) as Number_of_games_played
from(
select distinct home_team,count(home_team) as Number_of_app--selects the number of games each team in the 'home' column plays
from worldcup
group by home_team
union all--combines the output from both statements
select distinct away_team,count(away_team) as Number_of_app--selects the number of games each team in the 'away' column plays
from worldcup
group by away_team
) as Numberofgames
group by home_team
order by Number_of_games_played desc

--Joining the two temporary tables and calculating the win percentage of each team
select gp.Team,gp.Games_played,w.Wins,Wins/Games_played*100 as Win_percentage
from #gamesplayed as gp
join #wins as w on
gp.Team=w.Team
order by Win_percentage desc

--Number of Goals each team has scored in the competition
select distinct home_team as Team,sum(goalsscored) as goals_scored
from
(select distinct home_team, sum(home_score) as goalsscored
from worldcup
group by home_team
union all
select distinct away_team, sum(away_score) as goalsscored
from worldcup
group by away_team) as Goals
group by home_team
order by goals_scored desc

--World Cup Winners
select match_date,home_team,away_team,home_score,away_score,results
from(
select max(match_date)over(partition by year(match_date))as final_date,
match_date,home_team,away_team,home_score,away_score,
city,country,neutral,case when home_score>away_score then home_team
				when away_score>home_score then away_team
				else 'Penaltyshootouts' end as results
from worldcup
)as finals
where final_date=match_date
order by year(match_date)
--creating a temp table for the finals data
create table #finals
(match_date date,home_team nvarchar(100),away_team nvarchar(100),
home_score int,away_score int,results nvarchar(100))
insert into #finals
select match_date,home_team,away_team,home_score,away_score,results
from(
select max(match_date)over(partition by year(match_date))as final_date,
match_date,home_team,away_team,home_score,away_score,
city,country,neutral,case when home_score>away_score then home_team
				when away_score>home_score then away_team
				else 'Penaltyshootouts' end as results
from worldcup
)as finals
where final_date=match_date
order by year(match_date)
--selecting duplicate rows
select * 
from #finals
where year(match_date) in('1938','1950')
--deleting wrong rows
delete 
from #finals
where year(match_date) in('1938','1950')and(home_team='Spain' or away_team='Sweden')
--Discovering the results of the penalty shootouts
select f.match_date,f.home_team,f.away_team,f.home_score,
f.away_score,isnull(winner,results)as winner
from #finals f
left join penaltyshootouts ps
on f.match_date=ps.match_date
order by match_date

--Highest scoring game
select *,home_score+away_score as totalmatchscore
from worldcup
order by totalmatchscore desc
--Highest scoring draw
select *,home_score+away_score as totalmatchscore
from worldcup
where home_score=away_score
order by totalmatchscore desc
--Highest scoring final
select *,home_score+away_score as totalmatchscore
from #finals
order by totalmatchscore desc

--Most shootout wins
select winner,count(winner) as Numberofwins
from(
select wc.match_date,wc.home_team,wc.away_team,home_score,away_score,winner
from worldcup wc
join penaltyshootouts ps
on wc.match_date=ps.match_date
where home_score=away_score) as pens
group by winner
order by Numberofwins desc,winner

--Tournament hosts
select distinct country,count(country) as No_hosted
from(
select distinct year(match_date) as wcyear,country--,count(country) as No_hosted
from worldcup) as hosts
group by country
order by No_hosted desc,country