WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT
        l.linked_movie_id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        h.level + 1 AS level
    FROM 
        movie_link l
    JOIN 
        aka_title a ON l.linked_movie_id = a.id
    JOIN 
        movie_hierarchy h ON l.movie_id = h.movie_id
)
SELECT 
    h.movie_id,
    h.movie_title,
    h.production_year,
    COUNT(c.id) AS cast_count,
    STRING_AGG(DISTINCT p.name, ', ') AS cast_names,
    CASE 
        WHEN h.production_year IS NULL THEN 'No Year'
        WHEN h.production_year < 2010 THEN 'Older'
        ELSE 'Recent'
    END AS movie_age_category
FROM 
    movie_hierarchy h
LEFT JOIN 
    cast_info c ON h.movie_id = c.movie_id
LEFT JOIN 
    aka_name p ON c.person_id = p.person_id
LEFT JOIN 
    movie_info mi ON h.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary' LIMIT 1)
WHERE 
    p.name IS NOT NULL
GROUP BY 
    h.movie_id, h.movie_title, h.production_year
HAVING 
    COUNT(c.id) > 0
ORDER BY 
    h.production_year DESC, cast_count DESC
LIMIT 10;

This SQL query is designed to benchmark performance across several SQL constructs, including:

1. **Recursive CTE**: To build a hierarchy of movies based on linked movies from 2000 onwards.
2. **LEFT JOIN**: To ensure we select movies even if there are no cast members.
3. **STRING_AGG**: Collects the names of cast members into a comma-separated string.
4. **CASE Statement**: Classifies movies based on their production year.
5. **COUNT**: Counts the number of cast members for each movie.
6. **HAVING**: Ensures that only movies with cast members are included in the final results.
7. **ORDER BY** & **LIMIT**: Sorts the movies by production year and cast count, returning only the top 10 results. 

This query allows for an in-depth look at movies from a particular time frame while showcasing complex SQL features for performance analysis.
