/*
USED SQL SERVER 2019
SQL Server Management Studio19.0. 
 Operating System						10.0.19045*/


USE data_exploration_covid19

select top 5 * from CovidDeaths  
select top 5 * from CovidVaccinations  

-- lets check for distinct values for location and contitent



select distinct(continent) from CovidDeaths;
/* we have North America
Asia
Africa
Oceania
NULL
South America
Europe
*/
 
select distinct(location) from CovidDeaths where continent is   NULL;
-- we should be care when contient is null, we still Oceania International World
/* North America
Asia
World
Africa
Oceania--------------this is austrialia
European Union ---this is different
South America
International -- this not 
Europe*/


select distinct(location) from CovidDeaths where continent is not NULL order by location 
  /* we get countries */

-- we look for Totalcases VS Total Deaths, death percentage

select location,date,total_cases,total_deaths,(total_deaths/total_cases) as PercentageOfDeath 
--max(PercentageOfDeath) OVER (PARTITION BY PercentageOfDeath)
from CovidDeaths order by 1,2;

--we need to find the highest infection rate ie totalcases/population
select location,max(total_cases),population,max(total_cases/population) AS InfectionRate
from CovidDeaths 
--where location ='India'
group by location,population 
order by 1,2

-- we create procdure for getting highest infection rate per population by taking the IN paramter
drop procedure  InfectionRateOfGivenCountry


create procedure InfectionRateOfGivenCountry @country varchar(10) as 
select location,max(total_cases),population,
max(total_cases/population) AS InfectionRate
from CovidDeaths 
where location =@country
group by location,population
order by 1,2
 
exec   InfectionRateOfGivenCountry @country='India'
exec  InfectionRateOfGivenCountry @country='Germany'

-- find the highestInfectionRate for all countries
select location,max(total_cases) as cases_count  ,population,max((total_cases) /population)*100 as InfectionPerPopulation
from CovidDeaths
where continent is not null
group by location,population
order by location 

-- find the death count,highestDeathRate for all countries
select location,max(total_deaths) as death_count  ,population,max((total_deaths) /population)*100 as NoOfDeathsPerPopulation
from CovidDeaths
where continent is not null
group by location,population
order by location 

-- finding the country that has most death rate 
With theTop10CountriesWithHighDeathRate(Location,Death_count,Population,NoOfDeathsPerPopulation) 
as(select location,max(total_deaths) as death_count
,population,max((total_deaths) /population)*100 as NoOfDeathsPerPopulation
from CovidDeaths
where continent is not null
group by location,population
  )  select top 10  Location,population,Death_count,NoOfDeathsPerPopulation 
  from theTop10CountriesWithHighDeathRate
  where  NoOfDeathsPerPopulation is not null
  order by NoOfDeathsPerPopulation DESC
-- so the Hungary,Czechia,San Marino,Bosnia and Herzegovina,Montenegro are the top 5 among them


With theTop5CountriesWithLowestDeathRate(Location,Death_count,Population,NoOfDeathsPerPopulation) 
as(select location,max(convert(int,total_deaths)) as death_count
,population,max(convert(int,total_deaths)/population)*100 as NoOfDeathsPerPopulation
from CovidDeaths
where continent is not null
group by location,population
  )  select top 5  Location,population,Death_count,NoOfDeathsPerPopulation 
  from theTop5CountriesWithLowestDeathRate
  where  NoOfDeathsPerPopulation is not null
  order by NoOfDeathsPerPopulation ASC
-- so the Tanzania Vietnam Taiwan Burundi -- Bhutan



 
-- just to know death counts for various continents + world + europeUnion +internationa;
select location,max(convert(int,total_deaths)) as totalDeathCount 
from CovidDeaths where  continent is null 
group by location
order by totalDeathCount


-- to know the history of covid cases for a given country
drop procedure covidHistoryOfGivenCountry

create procedure covidHistoryOfGivenCountry @loc varchar(100) as 
select location,date,convert(int,new_cases) as nd,convert(int, total_cases) as tc, 
sum(convert(int,new_cases)) OVER (PARTITION BY location)
from CovidDeaths where location=@loc
order by date
exec covidHistoryOfGivenCountry @loc='yemen' 
exec covidHistoryOfGivenCountry @loc='Oman'  
 
-- we find total deaths and total cases from newcases and new_deaths and take the percentage of both

select date, sum(cast (new_cases as int))as cases, sum(cast (new_deaths as int)) as deaths,
(sum(cast (new_deaths as float))/sum( cast (new_cases as float)))*100 from
CovidDeaths 
where continent is not null
group by date

-- this for entire global cases and deaths and its death%
select  sum(cast (new_cases as int))as cases, sum(cast (new_deaths as int)) as deaths,
(sum(cast (new_deaths as float))/sum( cast (new_cases as float)))*100 AS worldDeathPercentage from
CovidDeaths 
where continent is not null
 

/* lets try to use the second table ie Covid Vaccination */

select * from CovidVaccinations


select cd.continent,cd.location,cd.date,cd.population as population ,convert(int,cd.total_cases) as totalCases,
convert(int,cv.total_vaccinations) as totalVaccination
from CovidDeaths cd JOIN CovidVaccinations cv on cd.date=cv.date and cd.location=cv.location
where cd.continent is not null and cd.continent='Africa'
order by 2,3

-- totalpopulation vs vaccination 
select cd.continent,cd.location,cd.date,cd.population as population , 
convert(int,cv.new_vaccinations) as  Vaccination,
sum(convert(int,cv.new_vaccinations)) OVER (PARTITION BY cd.location) as TotalVaccination
from CovidDeaths cd JOIN CovidVaccinations cv on cd.date=cv.date and cd.location=cv.location
where cd.continent is not null and cd.continent='Africa'
order by 2,3

select cd.continent,cd.location,cd.date,cd.population as population , 
convert(int,cv.new_vaccinations) as  Vaccination,
sum(convert(int,cv.new_vaccinations))
OVER (PARTITION BY cd.location order by cd.location,cd.date) as rollingPeopleVaccination
from CovidDeaths cd JOIN CovidVaccinations cv on cd.date=cv.date and cd.location=cv.location
where cd.continent is not null and cd.location='United States'
order by 2,3

-- it is not possible to add population/rollingPeopleVaccination after append to above query
-- so we use CTE or TEMP TABLES
/* CTE TABLES */

select cd.continent,cd.location,cd.date,cd.population as newpopulation , 
convert(int,cv.new_vaccinations) as  NewVaccination,
sum(convert(int,cv.new_vaccinations))
OVER (PARTITION BY cd.location order by cd.location,cd.date) as rollingPeopleVaccinated
from CovidDeaths cd JOIN CovidVaccinations cv on cd.date=cv.date and cd.location=cv.location
where cd.continent is not null  




--- the below query tells you the percentage of population that have been vaccinated. for each location.

With Population_vs_Vaccination (Continent,Location,Date,nPopulation,Vaccination,RollingPeopleVaccinated) as 
(select cd.continent,cd.location,cd.date,cd.population as newpopulation , 
convert(int,cv.new_vaccinations) as  NewVaccination,
sum(convert(int,cv.new_vaccinations))
OVER (PARTITION BY cd.location order by cd.location,cd.date) as rollingPeopleVaccinated
from CovidDeaths cd JOIN CovidVaccinations cv on cd.date=cv.date and cd.location=cv.location
where cd.continent is not null  
 
) select * ,(RollingPeopleVaccinated/nPopulation)*100 as VaccinationPercentage 
from Population_vs_Vaccination 


/* LETS USE TEMP TABLES */

create table #locationVaccinated( continent varchar(100), location varchar(100), date varchar(100),
population numeric, new_vaccinations numeric, rolling_people_vaccinated numeric)

Insert into #locationVaccinated 
select cd.continent,cd.location,cd.date,cd.population as newpopulation , 
convert(int,cv.new_vaccinations) as  NewVaccination,
sum(convert(int,cv.new_vaccinations))
OVER (PARTITION BY cd.location order by cd.location,cd.date) as rollingPeopleVaccinated
from CovidDeaths cd JOIN CovidVaccinations cv on cd.date=cv.date and cd.location=cv.location
 
-- here we wanted to vaccination progress for the entire country like India. as per result
-- it has vaccinated over 10% of India's population by April 30 2021


select *,(rolling_people_vaccinated/population)*100 as vaccinePercentage FROM #locationVaccinated  
where rolling_people_vaccinated is not null and location='India'

-- lets find using temp table #locationVaccinated  
select  location ,max(rolling_people_vaccinated) as vaccinatedpopulation ,population as totalpopulation, (max(rolling_people_vaccinated)/population)*100 as vaccinePercentage
FROM #locationVaccinated  group by location,population order by vaccinePercentage desc 
 

 -- create a view for Qatar
create view vaccinationProgressAt_QATAR as 
select cd.continent,cd.location,cd.date,cd.population as newpopulation , 
convert(int,cv.new_vaccinations) as  NewVaccination,
sum(convert(int,cv.new_vaccinations))
OVER (PARTITION BY cd.location order by cd.location,cd.date) as rollingPeopleVaccinated
from CovidDeaths cd JOIN CovidVaccinations cv on cd.date=cv.date and cd.location=cv.location
where cd.continent is not null  and cd.location='Qatar'

select * from vaccinationProgressAt_QATAR  where rollingPeopleVaccinated is not null