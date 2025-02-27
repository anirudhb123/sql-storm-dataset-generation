WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS hierarchy_level,
        CAST(mt.title AS VARCHAR(255)) AS full_title
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.hierarchy_level + 1,
        CAST(mh.full_title || ' -> ' || mt.title AS VARCHAR(255)) AS full_title
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    wh.title,
    wh.production_year,
    wh.hierarchy_level,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
FROM 
    MovieHierarchy wh
LEFT JOIN 
    complete_cast cc ON wh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    wh.hierarchy_level < 3 -- Limiting to a depth of 3 for performance
GROUP BY 
    wh.movie_id, wh.title, wh.production_year, wh.hierarchy_level
ORDER BY 
    wh.production_year DESC, wh.hierarchy_level, cast_count DESC
LIMIT 100;

WITH TitleKeywords AS (
    SELECT
        mt.id AS movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM
        aka_title mt
    LEFT JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY
        mt.id
)

SELECT 
    th.title,
    th.production_year,
    tw.keywords,
    COALESCE(COUNT(DISTINCT ci.person_id) FILTER (WHERE ci.role_id IS NOT NULL), 0) AS total_roles,
    COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS noted_roles
FROM 
    aka_title th
LEFT JOIN 
    TitleKeywords tw ON th.id = tw.movie_id
LEFT JOIN 
    complete_cast cc ON th.id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
WHERE 
    th.production_year >= 2015
GROUP BY 
    th.id, th.title, th.production_year, tw.keywords
HAVING 
    total_roles > 0
ORDER BY 
    total_roles DESC
LIMIT 50;

