WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, 
           mt.title,
           1 AS depth
    FROM aka_title mt

    WHERE mt.production_year >= 2000  -- condition to consider more recent movies

    UNION ALL
    
    SELECT ml.linked_movie_id, 
           at.title,
           mh.depth + 1
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    STRING_AGG(DISTINCT t.title, ', ') AS movie_titles,
    AVG(CASE WHEN mi.info IS NOT NULL THEN LENGTH(mi.info) ELSE 0 END) AS avg_info_length,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count
FROM aka_name a
LEFT JOIN cast_info ci ON a.person_id = ci.person_id
LEFT JOIN complete_cast cc ON ci.movie_id = cc.movie_id
LEFT JOIN MovieHierarchy mh ON cc.movie_id = mh.movie_id
LEFT JOIN movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN aka_title t ON mh.movie_id = t.id
WHERE a.name IS NOT NULL
GROUP BY a.name
HAVING COUNT(DISTINCT mh.movie_id) > 0   -- ensuring only actors with movies are selected
ORDER BY total_movies DESC
LIMIT 10;

-- Additional benchmarking by retrieving movies with the most actors involved
SELECT 
    mt.title,
    COUNT(DISTINCT ci.person_id) AS actor_count
FROM aka_title mt
JOIN cast_info ci ON mt.id = ci.movie_id
GROUP BY mt.title
HAVING COUNT(DISTINCT ci.person_id) = (SELECT MAX(actor_count) 
                                        FROM (SELECT COUNT(DISTINCT ci2.person_id) AS actor_count
                                              FROM aka_title mt2
                                              JOIN cast_info ci2 ON mt2.id = ci2.movie_id
                                              GROUP BY mt2.title) AS actor_counts)
ORDER BY actor_count DESC;

This SQL query utilizes various constructs including:
- A recursive CTE (`MovieHierarchy`) to create a hierarchy of movies linked together.
- Multiple joins including outer joins to connect different tables.
- Aggregation functions like `COUNT`, `AVG`, and `STRING_AGG` to analyze the data.
- Conditions such as `HAVING` to filter results based on aggregated counts.
- It retrieves both actor names along with the number of movies they have acted in and lists the movies with the highest actor involvement.
