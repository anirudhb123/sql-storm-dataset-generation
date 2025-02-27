WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
), 
cast_stats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id 
    GROUP BY 
        ci.movie_id
), 
keyword_summary AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.actor_names, 'No cast') AS actor_names,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    mh.level,
    CASE 
        WHEN mh.level > 1 THEN 'Sequel/Related'
        ELSE 'Standalone'
    END AS movie_type
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_stats cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    keyword_summary ks ON mh.movie_id = ks.movie_id
WHERE 
    mh.level <= 3
ORDER BY 
    mh.level, mh.movie_title;
