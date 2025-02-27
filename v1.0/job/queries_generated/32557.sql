WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS hierarchy
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        CAST(mh.hierarchy || ' -> ' || at.title AS VARCHAR(255))
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.hierarchy,
    mh.production_year,
    COUNT(CASE WHEN c.role_id IS NOT NULL THEN 1 END) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    AVG(mi.info_length) AS avg_info_length,
    MIN(m.id) AS first_movie_id,
    MAX(m.id) AS last_movie_id
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    aka_title m ON mh.movie_id = m.id
GROUP BY 
    mh.hierarchy, mh.production_year
ORDER BY 
    mh.production_year DESC, cast_count DESC;

This SQL query includes:

1. A recursive Common Table Expression (CTE) to create a hierarchy of linked movies.
2. Performance benchmarks such as counting distinct actors, aggregating keywords, and calculating average info length from different tables.
3. Outer joins to handle cases where there may not be any data in certain tables.
4. Use of complex data types like `STRING_AGG` and `ARRAY_AGG` for aggregating actor names and keywords.
5. Use of conditional logic for counting the number of actors linked to each movie.
6. Grouping and ordering to facilitate easy reading of performance metrics over different production years.
