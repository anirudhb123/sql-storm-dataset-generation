WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')  -- Assuming 'movie' is a valid kind

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
actor_movie_info AS (
    SELECT 
        a.name,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.id) AS cast_count,
        AVG(CASE WHEN mi.info_type_id IS NULL THEN 0 ELSE 1 END) AS has_info,  -- AVG to check presence of info
        COUNT(DISTINCT kw.id) AS keyword_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mw ON t.id = mw.movie_id
    LEFT JOIN 
        keyword kw ON mw.keyword_id = kw.id
    GROUP BY 
        a.name, t.title, t.production_year
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    am.name AS actor_name,
    am.cast_count,
    am.keyword_count,
    CASE WHEN am.has_info > 0 THEN 'Yes' ELSE 'No' END AS has_info
FROM 
    movie_hierarchy mh
JOIN 
    actor_movie_info am ON mh.title = am.title AND mh.production_year = am.production_year
WHERE 
    mh.level <= 2  -- Limit depth for performance benchmarking
ORDER BY 
    mh.production_year DESC,
    am.cast_count DESC,
    am.keyword_count DESC
LIMIT 100;
