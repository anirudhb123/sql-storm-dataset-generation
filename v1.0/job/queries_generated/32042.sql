WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000 
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    INNER JOIN movie_link ml ON mh.movie_id = ml.movie_id
    INNER JOIN aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 5  -- Limiting the depth of the recursion
)
SELECT 
    ak.name AS actor_name,
    a.title AS movie_title,
    a.production_year,
    COUNT(DISTINCT a.id) OVER (PARTITION BY ak.person_id) AS total_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COALESCE(ci.note, 'No Role') AS role_note
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title a ON ci.movie_id = a.movie_id
LEFT JOIN 
    movie_keyword mk ON a.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ak.name LIKE '%Smith%'  -- Filtering for names that include 'Smith'
    AND a.production_year BETWEEN 2010 AND 2020
    AND EXISTS (
        SELECT 1 
        FROM complete_cast cc
        WHERE cc.movie_id = a.id 
        AND cc.subject_id = ak.id 
        AND cc.status_id IS NOT NULL
    )
GROUP BY 
    ak.name, a.title, a.production_year, ci.note
ORDER BY 
    total_movies DESC, a.production_year ASC;

This SQL query utilizes several advanced SQL features, including:

1. **Recursive Common Table Expression (CTE)** to build a hierarchy of movies linked to each other based on production year.
2. **Outer Join** to include movie keywords, allowing flexibility for movies that may not have associated keywords.
3. **Window functions** (with `COUNT(DISTINCT) OVER()`) to calculate the total number of movies per actor without disrupting the grouping.
4. **String Aggregation** (`STRING_AGG` function) to combine keywords into a single field for each movie.
5. **Complicated predicates** in the WHERE clause for casting information and ensuring certain conditions (like actor names, production year, and relationships).
6. **NULL logic** using `COALESCE` to provide a default value for roles that may not be available.

This query is designed to benchmark the performance of complex joins, grouping, and aggregations in a database with potentially large datasets.
