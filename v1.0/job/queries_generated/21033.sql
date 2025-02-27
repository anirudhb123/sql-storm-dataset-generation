WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
, cast_details AS (
    SELECT 
        ca.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM 
        cast_info ca
    LEFT JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    GROUP BY 
        ca.movie_id
)
, movie_keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cd.actors, 'No actors') AS actors,
    COALESCE(cd.actor_count, 0) AS actor_count,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN mh.level > 1 THEN 'Part of series'
        ELSE 'Standalone movie'
    END AS movie_type,
    (
        SELECT 
            COUNT(DISTINCT ci.id) 
        FROM 
            complete_cast ci 
        WHERE 
            ci.movie_id = mh.movie_id 
            AND ci.status_id IS NOT NULL
    ) AS complete_cast_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    movie_keyword_count mkc ON mh.movie_id = mkc.movie_id
WHERE 
    (mh.production_year BETWEEN 2000 AND 2023)
    AND (mh.production_year IS NOT NULL OR cd.actor_count > 0)
ORDER BY 
    mh.production_year DESC,
    actor_count DESC,
    keyword_count DESC;

WITH NULL_AS_NOT_NULL AS (
    SELECT 
        NULLIF(ak.name, '') AS actor_name
    FROM 
        aka_name ak
    WHERE 
        ak.name IS NOT NULL
)
SELECT 
    m.title,
    CASE 
        WHEN na.actor_name IS NOT NULL THEN na.actor_name
        ELSE 'Unknown Actor'
    END AS actor_name
FROM 
    aka_title m
LEFT JOIN 
    NULL_AS_NOT_NULL na ON m.id = (SELECT id FROM cast_info ci WHERE ci.movie_id = m.id LIMIT 1);
