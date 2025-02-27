WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::integer AS parent_id,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.movie_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mh.title AS linked_movie_title,
    mh.production_year AS linked_movie_year,
    ak.name AS actor_name,
    COUNT(*) OVER (PARTITION BY ak.id) AS movie_count,
    CASE 
        WHEN ak.gender = 'M' THEN 'Male Actor'
        WHEN ak.gender = 'F' THEN 'Female Actor'
        ELSE 'Unknown Gender'
    END AS actor_gender,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MAX(mi.info) FILTER (WHERE it.info = 'box office') AS box_office_info
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
JOIN 
    cast_info ca ON ca.id = cc.subject_id
JOIN 
    aka_name ak ON ak.person_id = ca.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id
LEFT JOIN 
    info_type it ON it.id = mi.info_type_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, ak.id, ak.gender, mh.production_year
HAVING 
    COUNT(DISTINCT k.keyword) > 2
ORDER BY 
    mh.production_year DESC, actor_name;

### Explanation:

1. **Recursive CTE (MovieHierarchy)**: This is used to create a hierarchy of movies starting from those produced in the year 2000 or later. It pulls in both the main movies and their linked movies.
  
2. **Aggregation**: The query aggregates information such as the count of movies per actor, a string concatenation of keywords associated with each movie, and captures the maximum box office info.

3. **Filtering**: The filtering conditions dynamically assess the actor's gender and ensure that only actors with more than two distinct movie keywords are included.

4. **Outer Joins**: Utilization of `LEFT JOIN` allows for the integration of optional related data, such as keywords and box office information, without excluding movies that may not have this data.

5. **Window Functions**: COUNT() as a window function provides the ability to count movies per actor while maintaining the row-level detail.

This query provides an extensive benchmarking capability by combining various SQL constructs to test the performance under different join scenarios while aggregating and filtering data accordingly.
