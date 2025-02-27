WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS level,
        CAST(mt.title AS VARCHAR(255)) AS hierarchy
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
  
    UNION ALL
  
    SELECT 
        ml.linked_movie_id,
        ml.linked_title,
        mh.level + 1,
        CAST(mh.hierarchy || ' -> ' || ml.linked_title AS VARCHAR(255))
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title AS main_title,
    mh.level,
    mh.hierarchy,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    MAX(mk.keyword) AS top_keyword
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.level <= 2
GROUP BY 
    mh.movie_id, mh.title, mh.level, mh.hierarchy
HAVING 
    COUNT(DISTINCT a.name) > 1
ORDER BY 
    mh.level DESC, total_cast DESC;

-- Additional stats to compare based on movie companies and their types
SELECT 
    c.name AS company_name,
    ct.kind AS company_type,
    COUNT(DISTINCT mc.movie_id) AS total_movies
FROM 
    movie_companies mc
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
GROUP BY 
    c.name, ct.kind
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5
ORDER BY 
    total_movies DESC;

-- Final overall performance benchmark
WITH movie_statistics AS (
    SELECT 
        title AS main_title,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(m.production_year) AS average_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.title
)

SELECT 
    *,
    CASE 
        WHEN cast_count > 10 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity
FROM 
    movie_statistics
WHERE 
    average_year > 2010
ORDER BY 
    cast_count DESC, keyword_count DESC;
