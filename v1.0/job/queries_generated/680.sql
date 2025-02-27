WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rn,
        COUNT(mk.keyword) OVER (PARTITION BY mt.id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        cnt.movie_id,
        cnt.nr_order
    FROM 
        cast_info cnt
    INNER JOIN 
        aka_name ak ON cnt.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.keyword_count,
    ai.actor_name,
    COALESCE(ai.nr_order, 999) AS actor_order
FROM 
    TopMovies tm
LEFT JOIN 
    ActorInfo ai ON tm.movie_id = ai.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.keyword_count DESC, 
    actor_order ASC
LIMIT 100;
