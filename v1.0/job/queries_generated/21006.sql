WITH recursive movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.season_nr,
        mt.episode_nr,
        0 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.season_nr,
        mt.episode_nr,
        mh.level + 1 AS level,
        CAST(mh.path || ' -> ' || mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
actor_movies AS (
    SELECT 
        ca.person_id,
        ar.name AS actor_name,
        mv.movie_id,
        mv.title,
        mv.production_year,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY mv.production_year DESC) as recent_movie_rank
    FROM 
        cast_info ca
    JOIN 
        aka_name ar ON ca.person_id = ar.person_id
    JOIN 
        aka_title mv ON ca.movie_id = mv.id
),
movies_info AS (
    SELECT 
        movie_id,
        STRING_AGG(DISTINCT CAST(info.info AS VARCHAR), ', ') AS movie_keywords
    FROM 
        movie_info_info mi
    JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    a.actor_name,
    a.recent_movie_rank,
    mi.movie_keywords,
    CASE 
        WHEN mh.production_year IS NULL THEN 'Unknown Year'
        ELSE 'Year: ' || mh.production_year
    END AS year_info,
    CASE 
        WHEN a.recent_movie_rank = 1 
        THEN 'Latest Movie'
        ELSE 'Earlier Movie'
    END AS movie_status
FROM 
    movie_hierarchy mh
LEFT JOIN 
    actor_movies a ON mh.movie_id = a.movie_id
LEFT JOIN 
    movies_info mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.level < 3 AND 
    (mh.production_year IS NOT NULL OR a.actor_name IS NOT NULL)
ORDER BY 
    mh.production_year DESC,
    a.actor_name NULLS LAST,
    mh.path;

