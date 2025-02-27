WITH RecursiveMovieData AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(m.production_year, 'Unknown') AS production_year,
        COALESCE(aka.name, 'Unknown') AS actor_name,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY aka.name) AS actor_order
    FROM 
        aka_title AS m
    LEFT JOIN 
        cast_info AS ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name AS aka ON ci.person_id = aka.person_id
    LEFT JOIN 
        movie_companies AS mc ON mc.movie_id = m.id
    WHERE 
        m.production_year IS NOT NULL 
        AND m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year, aka.name
),
KeyMovieData AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        STRING_AGG(DISTINCT rm.actor_name, ', ') AS actors,
        MAX(rm.num_companies) AS max_companies
    FROM 
        RecursiveMovieData rm
    WHERE 
        rm.actor_order <= 3
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year
),
FinalOutput AS (
    SELECT 
        k.movie_id,
        k.movie_title,
        k.production_year,
        k.actors,
        k.max_companies,
        CASE 
            WHEN k.max_companies IS NULL THEN 'No Companies'
            WHEN k.max_companies = 0 THEN 'Independent'
            ELSE 'Produced' 
        END AS production_status
    FROM 
        KeyMovieData k
    WHERE 
        k.max_companies > 1
    ORDER BY 
        k.production_year DESC, k.movie_title ASC
)
SELECT 
    f.movie_id,
    f.movie_title,
    f.production_year,
    f.actors,
    f.max_companies,
    f.production_status,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM title t 
            WHERE t.title LIKE '%' || f.movie_title || '%'
        ) THEN 'Exists in Title' 
        ELSE 'Not Found in Title' 
    END AS title_existence_check
FROM 
    FinalOutput f
FULL OUTER JOIN 
    aka_name an ON an.name = ANY(STRING_TO_ARRAY(f.actors, ', '))
WHERE 
    (an.name IS NOT NULL OR f.production_year = 'Unknown')
ORDER BY 
    f.max_companies DESC NULLS FIRST, f.movie_title;
