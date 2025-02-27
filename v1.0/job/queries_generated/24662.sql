WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(mt.title, 'Unknown Title') AS title,
        COALESCE(ca.name, 'Unknown Actor') AS actor_name,
        ca.id AS actor_id,
        0 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = mt.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ca ON ci.person_id = ca.person_id

    UNION ALL 

    SELECT 
        mh.movie_id,
        mh.title,
        COALESCE(ca.name, 'Unknown Actor') AS actor_name,
        ca.id AS actor_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ca ON ci.person_id = ca.person_id 
    WHERE 
        mh.level < 10  -- Limit depth to avoid infinite recursion
),
actor_movie_counts AS (
    SELECT 
        actor_id,
        COUNT(DISTINCT movie_id) AS movie_count
    FROM 
        movie_hierarchy
    GROUP BY 
        actor_id
),
most_prolific_actors AS (
    SELECT 
        actor_id,
        actor_name, 
        movie_count,
        RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        actor_movie_counts ac
    JOIN 
        aka_name an ON ac.actor_id = an.person_id
),
seasonal_actor_movies AS (
    SELECT 
        mt.production_year,
        mh.actor_id,
        mh.actor_name,
        COUNT(*) AS movies_played
    FROM 
        movie_hierarchy mh
    JOIN 
        aka_title mt ON mh.movie_id = mt.id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.production_year, mh.actor_id, mh.actor_name
)
SELECT 
    ma.actor_name,
    ma.movie_count,
    sm.production_year,
    sm.movies_played,
    COALESCE(ROUND(AVG(sm.movies_played) OVER (PARTITION BY sm.production_year), 2), 0) AS avg_movies_per_actor,
    COUNT(DISTINCT ml.linked_movie_id) AS linked_movies_count,
    SUM(CASE WHEN mt.kind_id IS NULL THEN 1 ELSE 0 END) AS missing_kind_count
FROM 
    most_prolific_actors ma
LEFT JOIN 
    seasonal_actor_movies sm ON ma.actor_id = sm.actor_id
LEFT JOIN 
    movie_link ml ON ma.actor_id = ml.movie_id
LEFT JOIN 
    aka_title mt ON ml.linked_movie_id = mt.id
WHERE 
    ma.rank <= 10
GROUP BY 
    ma.actor_name, ma.movie_count, sm.production_year, sm.movies_played
ORDER BY 
    ma.movie_count DESC, sm.production_year;
