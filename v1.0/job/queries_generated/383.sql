WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.kind_id = 1
), AvgReleaseYear AS (
    SELECT 
        AVG(production_year) AS avg_year
    FROM 
        RankedTitles
    WHERE 
        rank <= 5
), CompanyFounded AS (
    SELECT 
        c.name AS company_name,
        c.country_code,
        COUNT(m.movie_id) AS total_movies
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    JOIN 
        aka_title m ON mc.movie_id = m.movie_id
    GROUP BY 
        c.name, c.country_code
    HAVING 
        COUNT(m.movie_id) > (SELECT avg_year FROM AvgReleaseYear)
)
SELECT 
    rt.actor_name,
    rt.title,
    c.company_name,
    c.country_code
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyFounded c ON rt.production_year >= 2000
WHERE 
    rt.rank <= 3 
    AND (c.country_code IS NOT NULL OR c.company_name IS NULL)
ORDER BY 
    rt.actor_name, rt.production_year DESC;
