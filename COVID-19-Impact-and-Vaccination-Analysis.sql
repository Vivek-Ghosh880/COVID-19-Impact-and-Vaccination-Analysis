--Covid 19 Data Exploration 
--Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

Select * From Project_Portfolio..Covid_Death;
Select * From Project_Portfolio..Covid_Vacination;

--Total Cases vs Total Deaths (Shows likelihood of dying if you contract covid for India)
SELECT Location, date, total_cases, total_deaths, 
    ROUND(((ISNULL(CONVERT(float, total_deaths), 0) / ISNULL(NULLIF(CONVERT(float, total_cases), 0), 1)) * 100), 2) as Death_Percentage 
FROM Project_Portfolio..Covid_Death 
WHERE Location = 'India'    
ORDER BY 1, 2;

-- Total Cases vs Population (Shows what percentage of population infected with Covid for India)
SELECT Location, date, Population, total_cases,
    ROUND((NULLIF(total_cases, 0) / Population) * 100, 2) as Percent_Population_Infected
FROM  Project_Portfolio..Covid_Death
WHERE Location = 'India' 
ORDER BY  1, 2;

-- Countries with Highest Infection Rate compared to Population
SELECT Location, Population, 
    MAX(total_cases) as Highest_Infection_Count,  
    ROUND(MAX((total_cases / Population)) * 100, 2) as Percent_Population_Infected
FROM  Project_Portfolio..Covid_Death
GROUP BY Location, Population
ORDER BY Location;

-- Countries with Highest Death Count per Population (excluding specific locations--world, high income, upper middle income, lower middle income)
SELECT Location, 
    MAX(CAST(Total_deaths AS INT)) as TotalDeathCount
FROM Project_Portfolio..Covid_Death
WHERE 
    Location NOT IN ('world', 'high income', 'upper middle income', 'lower middle income')
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Continents with the Highest Death Count per Population
SELECT continent, 
    MAX(CAST(Total_deaths AS INT)) as Total_Death_Count
FROM Project_Portfolio..Covid_Death
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_Death_Count DESC;

-- GLOBAL NUMBERS of Total Cases, Total Deaths and Death Percentage
SELECT 
    SUM(new_cases) as Total_Cases, 
    SUM(CAST(new_deaths AS INT)) as Total_Deaths, 
    ROUND(SUM(CAST(new_deaths AS INT)) / NULLIF(SUM(new_cases), 0) * 100, 2) as Death_Percentage
FROM Project_Portfolio..Covid_Death
WHERE continent IS NOT NULL;

								--joins 

-- Total Population vs Vaccinations (Shows Percentage of Population that has recieved at least one Covid Vaccine)
SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    ROUND(SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date),2) as Rolling_People_Vaccinated

FROM 
    Project_Portfolio..Covid_Death dea
JOIN 
    Project_Portfolio..Covid_Vacination vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL 
	AND dea.location ='India'
ORDER BY 
    dea.location, dea.date;

-- Using CTE to perform Calculation on Partition By in previous query
WITH Popvs_Vac (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
AS
(
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as Rolling_People_Vaccinated
    FROM
        Project_Portfolio..Covid_Death dea
    JOIN
        Project_Portfolio..Covid_Vacination vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE
        dea.continent IS NOT NULL 
		AND dea.location ='India'
)
SELECT *,
    ROUND((Rolling_People_Vaccinated / Population) * 100, 2) as Percentage_Vaccinated
FROM Popvs_Vac;


-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated bigint 
);

INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM
    Project_Portfolio..Covid_Death dea
JOIN
    Project_Portfolio..Covid_Vacination vac ON dea.location = vac.location AND dea.date = vac.date
	WHERE
        dea.continent IS NOT NULL 
		AND dea.location ='India';

-- Calculate percentage in the same query
Select *,
    (RollingPeopleVaccinated/NULLIF(Population, 0))*100 as PercentPopulationVaccinated
From   #PercentPopulationVaccinated;


-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated,
    CASE WHEN dea.population <> 0 THEN (SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) / dea.population) * 100 ELSE NULL END AS PercentPopulationVaccinated
FROM
    Project_Portfolio..Covid_Death dea
JOIN
    Project_Portfolio..Covid_Vacination vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
    AND dea.location ='India';













