WITH RecursiveTitleCTE AS (
    SELECT 
        title.id AS title_id,
        title.title,
        aka_title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.id ORDER BY aka_title.production_year DESC) AS rnk
    FROM 
        title
    LEFT JOIN 
        aka_title ON title.id = aka_title.movie_id
    WHERE 
        aka_title.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        aka_name.person_id,
        aka_name.name,
        COUNT(DISTINCT cast_info.movie_id) AS movie_count,
        SUM(CASE WHEN aka_title.kind_id = 1 THEN 1 ELSE 0 END) AS feature_film_count -- Assuming kind_id=1 relates to feature films
    FROM 
        aka_name
    JOIN 
        cast_info ON aka_name.person_id = cast_info.person_id
    LEFT JOIN 
        aka_title ON cast_info.movie_id = aka_title.movie_id
    GROUP BY 
        aka_name.person_id, aka_name.name
),
MoviesWithActors AS (
    SELECT 
        t.title,
        t.production_year,
        ai.name AS actor_name,
        ai.movie_count,
        ai.feature_film_count
    FROM 
        RecursiveTitleCTE t
    LEFT JOIN 
        cast_info c ON t.title_id = c.movie_id
    LEFT JOIN 
        ActorInfo ai ON c.person_id = ai.person_id
    WHERE 
        t.rnk = 1 -- Most recent production year for each title
),
TheaterInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT ci.person_id) AS num_actors,
        COALESCE(SUM(mi.info_type_id), 0) AS info_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        complete_cast cc ON mc.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id
    GROUP BY 
        mc.movie_id
)
SELECT 
    m.title,
    m.production_year,
    m.actor_name,
    m.movie_count,
    m.feature_film_count,
    ti.num_actors,
    ti.info_count
FROM 
    MoviesWithActors m
LEFT JOIN 
    TheaterInfo ti ON m.title = ti.movie_id
WHERE 
    (m.feature_film_count > 2 OR m.movie_count > 5) -- Filter actors based on roles in multiple films
    AND (ti.num_actors IS NULL OR ti.num_actors != 0) -- Ensure there are actors attached to the movies
ORDER BY 
    m.production_year DESC, 
    m.feature_film_count DESC 
LIMIT 
    100;
