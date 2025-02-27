WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        
    UNION ALL
    
    SELECT 
        mm.movie_id AS movie_id,
        mm.title,
        mm.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mm ON ml.linked_movie_id = mm.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT c.person_id) AS actor_count,
    ARRAY_AGG(DISTINCT a.name) AS actor_names,
    MAX(s.name) AS subject_name,
    SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'box office') THEN CAST(mi.info AS integer) ELSE 0 END) AS total_box_office
FROM 
    MovieHierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    aka_name a ON cc.subject_id = a.person_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    title t ON m.movie_id = t.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    char_name s ON s.imdb_id = m.movie_id
WHERE 
    m.production_year IS NOT NULL
AND 
    (s.name IS NOT NULL OR pi.info IS NULL)
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 5
ORDER BY 
    total_box_office DESC
LIMIT 10;

This query performs the following actions:

1. **Recursive CTE (Common Table Expression)**: Constructs a hierarchy of movies linked together by links defined in the `movie_link` table.
2. **Aggregations**: Counts the number of distinct actors per movie and aggregates their names into an array.
3. **Conditionals and Case Statements**: Calculates the total box office from the `movie_info` table based on a specific `info_type_id`.
4. **Various Joins**: Combines information from multiple tables to glean a comprehensive view of movie titles, their associated actors, and box office information.
5. **HAVING Clause**: Filters movies that have more than 5 distinct actors.
6. **Ordering and Limiting**: Results are ordered by total box office in descending order, limited to the top 10.
