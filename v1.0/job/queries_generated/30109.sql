WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COALESCE(cast.role_id, -1) AS role_id,
    COUNT(DISTINCT mw.id) OVER (PARTITION BY ak.person_id) AS movie_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    RANK() OVER (PARTITION BY ak.person_id ORDER BY at.production_year DESC) AS rank_recent_work,
    mh.level AS hierarchy_level
FROM 
    aka_name ak
LEFT JOIN 
    cast_info cast ON ak.person_id = cast.person_id
LEFT JOIN 
    aka_title at ON cast.movie_id = at.id
LEFT JOIN 
    movie_keyword mw ON at.id = mw.movie_id
LEFT JOIN 
    keyword kw ON mw.keyword_id = kw.id
JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND (at.production_year BETWEEN 2000 AND 2023 OR at.production_year IS NULL)
GROUP BY 
    ak.person_id, ak.name, at.title, at.production_year, cast.role_id, mh.level
ORDER BY 
    actor_name ASC, movie_title DESC, production_year ASC;
