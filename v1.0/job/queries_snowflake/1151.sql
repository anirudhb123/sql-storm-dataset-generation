
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS rank
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
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year,
        ac.actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCount ac ON rm.movie_id = ac.movie_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    tm.title, 
    tm.production_year, 
    COALESCE(tm.actor_count, 0) AS actor_count,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = tm.movie_id) AS info_count,
    (SELECT LISTAGG(k.keyword, ', ') 
     WITHIN GROUP (ORDER BY k.keyword) 
     FROM movie_keyword mk 
     JOIN keyword k ON mk.keyword_id = k.id 
     WHERE mk.movie_id = tm.movie_id) AS keywords,
    CASE 
        WHEN tm.actor_count IS NULL THEN 'No Cast'
        WHEN tm.actor_count = 0 THEN 'No Actors'
        ELSE 'Has Cast'
    END AS cast_status
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
