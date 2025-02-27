WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON a.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    m.level,
    COUNT(cc.person_id) AS cast_count,
    STRING_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')'), ', ') AS cast_details
FROM 
    MovieHierarchy m
LEFT JOIN 
    complete_cast cc ON cc.movie_id = m.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = m.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
LEFT JOIN 
    role_type r ON r.id = ci.role_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
GROUP BY 
    m.movie_id, m.title, m.production_year, m.level
HAVING 
    COUNT(cc.person_id) > 2
ORDER BY 
    m.production_year DESC, m.cast_count DESC;

In this SQL query:
- **Common Table Expression (CTE)**: A recursive CTE named `MovieHierarchy` is used to traverse linked movies, creating a hierarchy of movies and their relationships.
- **LEFT JOINs**: There are multiple `LEFT JOINs` to fetch related information from several tables (`complete_cast`, `cast_info`, `aka_name`, and `role_type`), allowing us to aggregate cast details.
- **STRING_AGG**: This function aggregates the cast information into a single string format for better readability.
- **HAVING Clause**: Only movies with more than 2 cast members are considered.
- The results are grouped by movie details and cast count, ordered by the year of production and cast count for performance benchmarking analytic purposes.
