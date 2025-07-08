
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rn
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ac.actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.movie_id = ac.movie_id
    WHERE 
        rm.rn <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.actor_count, 0) AS actor_count,
    (SELECT LISTAGG(a.name, ', ') 
     FROM aka_name a 
     JOIN cast_info ci ON a.person_id = ci.person_id 
     WHERE ci.movie_id = tm.movie_id) AS actors,
    (SELECT COUNT(*) 
     FROM movie_keyword mk 
     WHERE mk.movie_id = tm.movie_id) AS keyword_count
FROM 
    TopMovies tm
GROUP BY 
    tm.title, 
    tm.production_year, 
    tm.actor_count
ORDER BY 
    tm.production_year DESC, 
    actor_count DESC;
