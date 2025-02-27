WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        m.title, 
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    kh.keyword,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    AVG(mh.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    COUNT(DISTINCT ci.person_id) AS total_cast_members
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kh ON mk.keyword_id = kh.id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    mh.level <= 3
GROUP BY 
    kh.keyword
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    movie_count DESC, avg_production_year ASC;

This query employs a recursive Common Table Expression (CTE) to explore a hierarchy of movies, collecting related movies linked through `movie_link`. It aggregates data from several tables, including `keyword`, `complete_cast`, and `cast_info`, and computes average production years and actor counts, applying various joins and groupings to produce a detailed summary. The filtering criteria apply complex conditions including levels in the hierarchy and thresholds on movie counts.
