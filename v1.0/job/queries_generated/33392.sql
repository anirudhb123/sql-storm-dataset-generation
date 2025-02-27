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
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.title,
    mh.level,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    SUM(CASE 
            WHEN ci.person_role_id IS NOT NULL THEN 1 
            ELSE 0 
        END) AS roles_assigned,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors_names,
    ARRAY_AGG(DISTINCT mk.keyword) AS movie_keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year IS NOT NULL 
    AND mh.kind_id IN (
        SELECT 
            id 
        FROM 
            kind_type 
        WHERE 
            kind IN ('movie', 'tv series')
    )
GROUP BY 
    mh.title, mh.level
ORDER BY 
    mh.production_year DESC, actor_count DESC;

### Explanation of SQL Query:
1. **CTE (Common Table Expression)**: The recursive `movie_hierarchy` CTE creates a hierarchy of movies produced from 2000 onwards and includes links between movies.
2. **OUTER JOINs**: Multiple LEFT JOINs are used to retrieve data from related tables like `complete_cast`, `cast_info`, `aka_name`, and `movie_keyword`.
3. **Column Aggregation**: `COUNT`, `SUM`, and `STRING_AGG` functions are utilized to get the count of distinct actors, count of roles assigned, and aggregate their names.
4. **Set Operator**: The subquery inside the `WHERE` clause filters `kind_id` to include only relevant movie types.
5. **NULL Logic**: The condition `mh.production_year IS NOT NULL` is included to ensure only valid production years are counted.
6. **Order by**: Results are ordered by the production year and actor count to showcase the most recent and collaborative titles first.
