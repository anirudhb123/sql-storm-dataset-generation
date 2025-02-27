
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS YearRank
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        CASE 
            WHEN t.production_year IS NULL THEN 'Unknown Year' 
            ELSE CAST(t.production_year AS VARCHAR)
        END AS production_year_str
    FROM 
        aka_title t
    LEFT JOIN 
        ActorCount ac ON t.id = ac.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    CASE 
        WHEN md.actor_count < 1 THEN 'No Actors' 
        WHEN md.actor_count BETWEEN 1 AND 5 THEN 'Few Actors' 
        ELSE 'Many Actors' 
    END AS actor_category,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    MovieDetails md
LEFT JOIN 
    movie_companies mc ON md.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    md.actor_count < 10
GROUP BY 
    md.title, md.production_year, md.actor_count
HAVING 
    COUNT(DISTINCT cn.id) > 0
ORDER BY 
    md.production_year DESC,
    md.title ASC
LIMIT 50
OFFSET 10;
