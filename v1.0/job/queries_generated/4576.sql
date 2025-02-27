WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS YearRank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
LongestTitle AS (
    SELECT 
        movie_id,
        title,
        LENGTH(title) AS title_length
    FROM 
        aka_title
    ORDER BY 
        title_length DESC
    LIMIT 1
)
SELECT 
    rm.title,
    rm.production_year,
    ac.actor_count,
    lt.title AS longest_title
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCount ac ON rm.id = ac.movie_id
LEFT JOIN 
    LongestTitle lt ON lt.movie_id = rm.id
WHERE 
    ac.actor_count IS NOT NULL 
    AND rm.YearRank <= 5
ORDER BY 
    rm.production_year ASC,
    ac.actor_count DESC
LIMIT 10;
