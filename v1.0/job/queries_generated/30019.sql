WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.production_year = 2020

    UNION ALL

    SELECT
        ml.linked_movie_id,
        mt.title,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    ARRAY_AGG(DISTINCT kc.keyword) AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY mh.depth) AS movie_rank,
    CASE 
        WHEN COUNT(DISTINCT kc.keyword) > 5 THEN 'Rich'
        WHEN COUNT(DISTINCT kc.keyword) BETWEEN 1 AND 5 THEN 'Moderate'
        ELSE 'Poor'
    END AS keyword_quality,
    COALESCE(ci.note, 'No note') AS actor_note,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND at.production_year >= 2010
    AND (ci.note IS NULL OR ci.note LIKE '%important%')
GROUP BY 
    ak.name, at.title, ci.note, mh.depth
ORDER BY 
    keyword_count DESC, ak.name;
