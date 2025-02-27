WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 
           1 AS level
    FROM title m
    WHERE m.production_year >= 2000

    UNION ALL 

    SELECT m.id, m.title, m.production_year, 
           mh.level + 1
    FROM title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    p.name AS person_name,
    COUNT(DISTINCT c.movie_id) AS num_movies,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    AVG(CASE WHEN (ci.nr_order IS NOT NULL) THEN ci.nr_order ELSE 0 END) AS avg_order,
    STRING_AGG(DISTINCT ki.keyword, ', ') AS keywords,
    mh.level AS movie_level
FROM aka_name p
LEFT OUTER JOIN cast_info ci ON p.person_id = ci.person_id
LEFT JOIN movie_companies mc ON ci.movie_id = mc.movie_id
LEFT JOIN MovieHierarchy mh ON mc.movie_id = mh.movie_id
LEFT JOIN movie_keyword mk ON mk.movie_id = ci.movie_id
LEFT JOIN keyword ki ON mk.keyword_id = ki.id
WHERE p.name IS NOT NULL
GROUP BY p.name, mh.level
ORDER BY num_movies DESC, p.name;

This SQL query generates a performance benchmark by creating a recursive Common Table Expression (CTE) to represent a hierarchy of movies linked by relationships. It selects the names of actors from the `aka_name` table, counts the distinct movies they have appeared in, aggregates their titles, calculates the average order of their roles while accounting for potential NULL values, and collects keywords associated with those movies. It uses outer joins to ensure all actors are included even if they have no listed movies and applies grouping and ordering to present organized results.
