
WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title) AS rank
    FROM 
        aka_title at
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorStats AS (
    SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(COALESCE(mh.duration_minutes, 0)) AS avg_movie_duration
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN 
        (SELECT 
            m.id AS movie_id,
            COALESCE(CAST(mi.info AS INT), 0) AS duration_minutes
         FROM 
            aka_title m
         LEFT JOIN 
            movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'duration')
        ) mh ON ci.movie_id = mh.movie_id
    GROUP BY 
        ak.id, ak.name
),
PopularActors AS (
    SELECT 
        actor_id,
        actor_name,
        movie_count,
        avg_movie_duration,
        RANK() OVER (ORDER BY movie_count DESC, avg_movie_duration DESC) AS actor_rank
    FROM 
        ActorStats
)
SELECT 
    pm.movie_id,
    pm.title,
    pm.production_year,
    pa.actor_name,
    pa.movie_count,
    pa.avg_movie_duration
FROM 
    RankedMovies pm
JOIN 
    cast_info ci ON pm.movie_id = ci.movie_id
JOIN 
    PopularActors pa ON ci.person_id = pa.actor_id
WHERE 
    pm.rank <= 5
ORDER BY 
    pm.production_year DESC, 
    pa.actor_rank, 
    pm.title;
