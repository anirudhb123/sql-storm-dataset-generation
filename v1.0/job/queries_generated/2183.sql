WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id
),
UniqueTitles AS (
    SELECT 
        DISTINCT rt.movie_title,
        rt.production_year
    FROM 
        RankedMovies rt
    WHERE 
        rt.rank <= 10
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        rt.movie_title,
        rt.production_year
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        UniqueTitles rt ON ci.movie_id = rt.movie_id
)
SELECT 
    ar.actor_name,
    ar.movie_title,
    ar.production_year,
    COALESCE(mi.info, 'No Info Available') AS additional_info
FROM 
    ActorRoles ar
LEFT JOIN 
    movie_info mi ON ar.movie_title = mi.info
WHERE 
    ar.production_year BETWEEN 2000 AND 2023
ORDER BY 
    ar.production_year, ar.actor_name;
