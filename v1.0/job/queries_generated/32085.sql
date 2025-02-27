WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        movie_link m
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = m.movie_id
)
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    mh.level AS movie_hierarchy_level, 
    COUNT(c.id) OVER (PARTITION BY t.id) AS cast_count,
    COALESCE(MIN(ki.keyword), 'No Keywords') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
JOIN 
    MovieHierarchy mh ON t.id = mh.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, mh.level
ORDER BY 
    mh.level, cast_count DESC, movie_title;

This SQL query utilizes a recursive common table expression (CTE) to create a movie hierarchy based on linked movies, counts the number of cast members for each movie, retrieves keywords associated with the movies, and uses window functions to count the cast members and grouping to present the relevant details. The query also incorporates outer joins and complex conditional logic, making it suitable for performance benchmarking.
