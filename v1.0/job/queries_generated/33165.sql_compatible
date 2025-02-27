
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        NULL AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
  
    UNION ALL
  
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mh.movie_id
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.actor_names, 'No cast') AS actor_names,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN mh.level = 0 THEN 'Main Movie'
        ELSE 'Episode'
    END AS movie_type
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year >= 2000
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, cs.total_cast, cs.actor_names, mk.keywords
ORDER BY 
    mh.production_year DESC, mh.title;
