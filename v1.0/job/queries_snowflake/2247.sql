WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
Actors AS (
    SELECT 
        ka.person_id, 
        ka.name, 
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    GROUP BY 
        ka.person_id, ka.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
TopActors AS (
    SELECT 
        a.name,
        a.movie_count,
        RANK() OVER (ORDER BY a.movie_count DESC) AS rank
    FROM 
        Actors a
    WHERE 
        a.name IS NOT NULL
)
SELECT 
    rm.title,
    rm.production_year,
    ta.name AS top_actor,
    rm.company_count,
    CASE 
        WHEN rm.company_count IS NULL THEN 'No companies'
        ELSE CAST(rm.company_count AS text) || ' companies'
    END AS company_info
FROM 
    RankedMovies rm
LEFT JOIN 
    TopActors ta ON ta.rank <= 10
WHERE 
    rm.year_rank = 1
ORDER BY 
    rm.production_year DESC, 
    rm.title;
