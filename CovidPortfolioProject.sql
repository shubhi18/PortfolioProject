/****** Script for SelectTopNRows command from SSMS  ******/

SELECT * 
FROM [PortfolioProject].[dbo].[CovidDeaths]
where continent is not null

-- selecting data to be used

SELECT [location] ,[date] ,[total_cases] ,[new_cases],[population] ,[total_deaths]
FROM [PortfolioProject].[dbo].[CovidDeaths]
where continent is not null
ORDER BY  1,2 ;

-- Looking at total cases vs total Deaths

SELECT [location] ,[date] ,[total_cases] ,[total_deaths] , (CAST(total_deaths AS float)/Cast(total_cases  AS float))*100 as DeathPercentage
FROM [PortfolioProject].[dbo].[CovidDeaths]
where location like '%states%' and  continent is not null
ORDER BY  1,2 ;


--Looking toatl cases Vs population


SELECT [location] ,[date] ,population ,[total_cases]   , (CAST(total_deaths AS float)/population)*100 as InfectedPopulationPercentage
FROM [PortfolioProject].[dbo].[CovidDeaths]
where continent is not null
ORDER BY  1,2 ;


--Looking at countries with highest infection rate 

SELECT location ,population ,max(total_cases) as highestInfectionCount  , 
Max((CAST(total_deaths AS float)/population)*100) as InfectedPopulationPercentage
FROM [PortfolioProject].[dbo].[CovidDeaths]
where continent is not null
group by location ,population 
ORDER BY  1,2 ;

--Showing countries with highest Death count per population

SELECT location ,max(cast(total_deaths as Float)) as highestDeathCount 
FROM [PortfolioProject].[dbo].[CovidDeaths]
where continent is not null
group by location  
ORDER BY  2 desc;


--Data on the basis of continent
SELECT continent ,max(cast(total_deaths as Float)) as highestDeathCount 
FROM [PortfolioProject].[dbo].[CovidDeaths]
where continent is not null
group by continent  
ORDER BY  2 desc;


--Global numbers

SELECT sum(new_cases) as totalCases, sum(cast(new_deaths as float)) as totalDeaths, 
sum(cast(new_deaths as INT))/sum(new_cases)*100 as DeathPercentage
FROM [PortfolioProject].[dbo].[CovidDeaths]
where  continent is not null
ORDER BY  1,2 ;


--COVID VACCINATIONS
select * from [PortfolioProject].[dbo].[CovidVaccinations];


-- looking at total population vs vaccinations
select * from [PortfolioProject].[dbo].[CovidDeaths] cd
join [PortfolioProject].[dbo].[CovidVaccinations] cv
on cd.location=cv.location and cd.date=cv.date;


select cd.continent , cd.location , cd.date , cd.population , cv.new_vaccinations
from [PortfolioProject].[dbo].[CovidDeaths] cd
join [PortfolioProject].[dbo].[CovidVaccinations] cv
on cd.location=cv.location and cd.date=cv.date
where cd.continent is not null
order by 2,3 ; 



with popVsVac (continent, location, date, population, new_vaccinations, totalPeopleVaccinated)
as (
select cd.continent , cd.location , cd.date , cd.population , cv.new_vaccinations,
sum(cast(cv.new_vaccinations as float)) over (partition by cd.location order by cd.location, cd.date) as totalPeopleVaccinated
from [PortfolioProject].[dbo].[CovidDeaths] cd
join [PortfolioProject].[dbo].[CovidVaccinations] cv
on cd.location=cv.location and cd.date=cv.date
where cd.continent is not null
--order by 2,3 
)
select * , (totalPeopleVaccinated/population)*100
from popVsVac;



--temp table 
DROP table if exists percentPopulationVaccinated
create table percentPopulationVaccinated 
(
continent nvarchar,
location nvarchar,
date datetime,
population float,
new_vaccinations float,
totalPeopleVaccinated float )


insert into percentPopulationVaccinated
select cd.continent , cd.location , cd.date , cd.population , cv.new_vaccinations,
sum(cast(cv.new_vaccinations as float)) over (partition by cd.location order by cd.location, cd.date) as totalPeopleVaccinated
from [PortfolioProject].[dbo].[CovidDeaths] cd
join [PortfolioProject].[dbo].[CovidVaccinations] cv
on cd.location=cv.location and cd.date=cv.date
where cd.continent is not null

select * , (totalPeopleVaccinated/population)*100
from percentPopulationVaccinated;


--create a view to store data for vuisulaization

Create View percentPopulationVaccinates as 

select cd.continent , cd.location , cd.date , cd.population , cv.new_vaccinations,
sum(cast(cv.new_vaccinations as float)) over (partition by cd.location order by cd.location, cd.date) as totalPeopleVaccinated
from [PortfolioProject].[dbo].[CovidDeaths] cd
join [PortfolioProject].[dbo].[CovidVaccinations] cv
on cd.location=cv.location and cd.date=cv.date
where cd.continent is not null;

select * from percentPopulationVaccinates;