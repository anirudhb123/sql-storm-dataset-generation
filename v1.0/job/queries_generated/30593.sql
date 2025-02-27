WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title AS movie_title, 0 AS level
    FROM aka_title m
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT m.id AS movie_id, m.title AS movie_title, mh.level + 1
    FROM aka_title m
    INNER JOIN movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    COUNT(DISTINCT c.id) AS total_cast,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    mh.movie_title AS linked_movies
FROM aka_name a
JOIN cast_info c ON a.person_id = c.person_id
JOIN aka_title t ON c.movie_id = t.id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_hierarchy mh ON t.id = mh.movie_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000 
    AND (c.note IS NULL OR c.note NOT LIKE '%cameo%')
GROUP BY
    a.name, t.title, mh.movie_title
ORDER BY
    total_cast DESC,
    avg_order ASC;

### Explanation:
- **CTE (`WITH RECURSIVE`)**: The `movie_hierarchy` CTE generates a hierarchical view of movies linked by relationships to facilitate querying for linked movies.
- **Main Query**: The main part aggregates data about actors, movies they participated in, their total count in the cast, average order in which they've appeared, and associated keywords.
- **Joins**: There are various outer and inner joins (using the `LEFT JOIN` and `JOIN` constructs), connecting people to their roles in movies, as well as connecting movies to their keywords.
- **Aggregation Functions**: The query uses `COUNT`, `AVG`, and `STRING_AGG` to derive interesting statistics, including total cast size and associated keywords.
- **WHERE Clause**: It applies filtering on production year and excludes certain roles based on notes, showcasing NULL logic.
- **ORDER BY**: The results are sorted based on the total number of cast members in descending order and the average order in ascending order, giving a clear priority in results.
