WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        mv.id AS movie_id,
        mv.title,
        mv.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS mv ON mv.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy AS mh ON mh.movie_id = ml.movie_id
)
SELECT 
    DISTINCT a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COALESCE(gk.keyword, 'No Keywords') AS keyword,
    COUNT(DISTINCT c.id) AS cast_count,
    AVG(CASE WHEN pi.info_type_id IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY m.production_year) AS avg_cast_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON c.person_id = a.person_id
JOIN 
    aka_title AS m ON m.id = c.movie_id
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = m.id
LEFT JOIN 
    keyword AS gk ON mk.keyword_id = gk.id
LEFT JOIN 
    person_info AS pi ON pi.person_id = a.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Birth Year')
WHERE 
    a.name IS NOT NULL AND
    m.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, m.title, m.production_year, gk.keyword
ORDER BY 
    m.production_year DESC, cast_count DESC
LIMIT 
    50;

This SQL query accomplishes the following:

- It uses a recursive Common Table Expression (CTE) `MovieHierarchy` to represent a hierarchy of movies from the year 2000 onwards.
- The query retrieves actor names, movie titles, production years, keywords (if any), and a count of distinct cast members for each movie.
- It calculates the average number of cast member info entries per production year using a window function.
- Outer joins are utilized to include movies even when they don't have associated keywords.
- The query filters for entries where `name` is not NULL and production years are between 2000 and 2023.
- Finally, it groups results to provide a summary and limits output to the top 50 entries sorted by production year and cast count.
