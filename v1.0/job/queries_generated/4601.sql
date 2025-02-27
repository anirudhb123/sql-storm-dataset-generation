WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    WHERE 
        c.nr_order IS NOT NULL
    GROUP BY 
        c.movie_id
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.id = ac.movie_id
    WHERE 
        rm.rn <= 10
)
SELECT 
    t.title,
    t.production_year,
    t.actor_count,
    CASE 
        WHEN t.actor_count > 5 THEN 'Major Cast'
        WHEN t.actor_count BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Minor Cast'
    END AS cast_size,
    (SELECT 
        STRING_AGG(DISTINCT char.name, ', ') 
     FROM 
        char_name char 
     INNER JOIN 
        cast_info ci ON char.imdb_id = ci.person_id 
     WHERE 
        ci.movie_id = t.movie_id
    ) AS actors
FROM 
    TopMovies t
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year DESC, t.actor_count DESC
LIMIT 20;
