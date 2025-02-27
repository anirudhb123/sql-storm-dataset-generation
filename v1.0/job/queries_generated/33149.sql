WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        ARRAY[mt.id] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 AS level,
        mh.path || ml.linked_movie_id
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        NOT ml.linked_movie_id = ANY(mh.path) -- Avoid infinite loops
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT c.id) AS total_cast,
    AVG(CASE WHEN m.production_year < 2000 THEN 1 ELSE NULL END) AS avg_cast_pre_2000,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    SUM(COALESCE(mi.info::integer, 0)) AS total_additional_info,
    MAX(CASE WHEN c.note IS NOT NULL THEN c.note ELSE 'No note' END) AS latest_note
FROM 
    movie_hierarchy m
JOIN 
    cast_info c ON m.movie_id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
GROUP BY 
    a.name, m.title, m.production_year
HAVING 
    COUNT(DISTINCT c.id) > 5
ORDER BY 
    m.production_year DESC, total_cast DESC;

This query performs the following:
1. Defines a recursive CTE `movie_hierarchy` to build a hierarchy of movies linked to each other.
2. Joins the hierarchy with `cast_info` to get cast data for each movie.
3. Joins with `aka_name` to get actor names.
4. Uses left joins to gather associated keywords and additional info (filtered to 'Budget').
5. Calculates aggregated metrics:
   - Total number of distinct cast members per movie.
   - Average cast members for movies produced before 2000.
   - Concatenates distinct keywords into a single string.
6. Uses `COALESCE` to handle potential NULL values in additional information.
7. Groups results by actor name and movie details.
8. Filters for movies with more than 5 unique cast members.
9. Orders results by production year and total cast in descending order.
