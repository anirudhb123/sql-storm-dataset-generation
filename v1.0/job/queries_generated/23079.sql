WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        0 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        CONCAT(mh.movie_title, ' -> ', lt.title) AS movie_title,
        lt.production_year,
        mh.level + 1,
        CONCAT(mh.path, ' -> ', lt.title)
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title lt ON ml.linked_movie_id = lt.id
)
, cast_with_role AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS actor_role,
        rn.rank AS role_rank,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY rn.rank DESC) AS rn
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        (SELECT 
            role_id, 
            ROW_NUMBER() OVER (ORDER BY role_id) AS rank
        FROM 
            role_type
        WHERE 
            role IS NOT NULL) rn ON ci.role_id = rn.role_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COALESCE(cwr.actor_name, 'No Actor') AS star_actor,
    MAX(cwr.actor_role) AS role_assigned,
    COUNT(DISTINCT cwr.movie_id) OVER (PARTITION BY mh.movie_id) AS total_projects,
    CASE 
        WHEN mh.production_year < 2000 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2000 AND 2015 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era,
    ARRAY_AGG(DISTINCT mt.keyword) AS associated_keywords,
    CASE 
        WHEN EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = mh.movie_id AND mi.info_type_id IS NOT NULL) 
        THEN 'Additional Info Exists' 
        ELSE 'No Additional Info' 
    END AS info_status
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_with_role cwr ON mh.movie_id = cwr.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword mt ON mk.keyword_id = mt.id
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, cwr.actor_name
ORDER BY 
    mh.production_year DESC, total_projects DESC
LIMIT 50 OFFSET 100;

This query retrieves a detailed report of movies, their associated actors, and various metrics, while employing multiple SQL constructs including CTEs, window functions, and conditional expressions. It provides deep insights into the movie relationships and actors' roles, along with the categorization of the movies based on production years and the existence of additional info related to the movies.
