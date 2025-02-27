WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
    GROUP BY 
        ci.person_id
),
PersonInfo AS (
    SELECT 
        ak.person_id,
        STRING_AGG(DISTINCT p.info, ', ') AS info
    FROM 
        aka_name ak
    LEFT JOIN 
        person_info p ON ak.person_id = p.person_id
    GROUP BY 
        ak.person_id
)
SELECT 
    ak.name AS actor_name,
    rm.title AS movie_title,
    rm.production_year,
    COALESCE(p.info, 'No additional info') AS additional_info,
    ac.movie_count AS total_movies
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    RankedMovies rm ON ci.movie_id = rm.movie_id
LEFT JOIN 
    PersonInfo p ON ak.person_id = p.person_id
LEFT JOIN 
    ActorMovieCounts ac ON ak.person_id = ac.person_id
WHERE 
    rm.production_year BETWEEN 2000 AND 2023
    AND (ac.movie_count IS NULL OR ac.movie_count > 5)
ORDER BY 
    rm.production_year DESC, 
    actor_name ASC;
