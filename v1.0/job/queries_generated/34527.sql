WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CAST(1 AS INTEGER) AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2010  -- Selecting movies after 2010 for modern context

    UNION ALL

    SELECT 
        mhl.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link mhl 
    JOIN 
        aka_title m ON m.id = mhl.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mhl.movie_id = mh.movie_id
)
SELECT 
    CONCAT_WS(', ', ak.name, ak.surname_pcode) AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT mw.keyword_id) AS keyword_count,
    SUM(CASE WHEN mk.keyword IS NOT NULL THEN 1 ELSE 0 END) AS synonym_count,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year DESC) AS movie_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_keyword mw ON mt.id = mw.movie_id
LEFT JOIN 
    keyword mk ON mw.keyword_id = mk.id
WHERE 
    ak.name IS NOT NULL 
    AND (mt.production_year IS NOT NULL OR mt.production_year = 0)
    AND ak.id IN (
        SELECT ak_inner.id
        FROM aka_name ak_inner
        INNER JOIN cast_info ci_inner ON ak_inner.person_id = ci_inner.person_id
        WHERE ci_inner.nr_order < 5
    )
GROUP BY 
    ak.person_id, mt.title, mt.production_year
ORDER BY 
    movie_rank, keyword_count DESC
LIMIT 100;
