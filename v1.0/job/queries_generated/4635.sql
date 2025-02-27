WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
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
MovieStats AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = rm.movie_id) AS info_count,
        (SELECT COUNT(DISTINCT mk.keyword_id) FROM movie_keyword mk WHERE mk.movie_id = rm.movie_id) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCount ac ON rm.movie_id = ac.movie_id
),
TopMovies AS (
    SELECT 
        ms.title,
        ms.production_year,
        ms.actor_count,
        ms.info_count,
        ms.keyword_count,
        RANK() OVER (ORDER BY ms.actor_count DESC, ms.production_year ASC) AS rank
    FROM 
        MovieStats ms
    WHERE 
        ms.actor_count > 0
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.info_count,
    tm.keyword_count,
    COALESCE(NULLIF(tm.actor_count, 0), 1) AS safe_actor_count -- Using NULL logic for safe division
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.actor_count DESC, tm.production_year;
