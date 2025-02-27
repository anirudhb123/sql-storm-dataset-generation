WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    ak.id AS actor_id,
    mv.title AS movie_title,
    mv.production_year,
    COUNT(DISTINCT r.role_id) AS roles_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(CASE 
            WHEN mv.level > 2 THEN 1 
            ELSE NULL 
        END) AS avg_nested_level,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY mv.production_year DESC) AS movie_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mv ON ci.movie_id = mv.movie_id
LEFT JOIN 
    movie_keyword mk ON mv.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    ak.name IS NOT NULL 
AND 
    mv.production_year > 2000
GROUP BY 
    ak.id, ak.name, mv.title, mv.production_year
HAVING 
    COUNT(DISTINCT r.role_id) > 0
ORDER BY 
    roles_count DESC, mv.production_year DESC;

This SQL query is designed to measure performance while retrieving detailed actor information, movie details, and their corresponding roles and keywords, incorporating various advanced constructs such as:
- A recursive Common Table Expression (CTE) to explore the hierarchy of linked movies.
- Joins that fetch actor information, their roles in movies, and associated keywords.
- Aggregate functions to calculate the count of distinct roles and an average indicating the level of movie nesting.
- STRING_AGG to concatenate keywords associated with movies.
- A row number window function to rank movies for each actor based on the production year.
- Filter criteria to focus on movies produced after the year 2000 and ensure that only actors with actual roles are returned.
