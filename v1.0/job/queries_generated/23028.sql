WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM 
        aka_title at
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
),
ActorMovies AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY at.production_year DESC) AS movie_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        ak.name IS NOT NULL
),
NullCheck AS (
    SELECT 
        person_id,
        COUNT(*) AS movie_count
    FROM 
        cast_info
    GROUP BY 
        person_id
    HAVING 
        COUNT(*) IS NULL OR COUNT(*) > 2
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code = 'USA'
)
SELECT DISTINCT
    at.title AS Movie_Title,
    at.production_year AS Production_Year,
    ak.name AS Actor,
    cm.company_name AS Production_Company,
    CASE 
        WHEN ak.name IS NULL THEN 'Unknown Actor' 
        ELSE ak.name 
    END AS Actor_Status,
    COALESCE(CASE 
        WHEN rt.year_rank >= 5 THEN 'Top Tier' 
        ELSE 'Lower Tier' 
    END, 'No Ranking') AS Ranking,
    (SELECT COUNT(*)
     FROM movie_keyword mk
     WHERE mk.movie_id = at.id
     HAVING COUNT(DISTINCT mk.keyword_id) > 5) AS Significant_Keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorMovies ak ON rt.title_id = ak.movie_title
LEFT JOIN 
    CompanyMovies cm ON rt.title_id = cm.movie_id
WHERE 
    rt.production_year BETWEEN 1990 AND 2020
    AND (ak.movie_rank <= 10 OR ak.movie_rank IS NULL)
    AND (cm.company_name IS NOT NULL OR cm.company_type IS NOT NULL)
ORDER BY 
    at.production_year DESC, 
    ak.name;
