WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, t.title, m.production_year, 0 AS level
    FROM aka_title m
    JOIN title t ON m.movie_id = t.id
    WHERE m.production_year >= 2000  -- Starting point for recent movies

    UNION ALL

    SELECT m.id AS movie_id, t.title, m.production_year, h.level + 1
    FROM aka_title m
    JOIN title t ON m.movie_id = t.id
    JOIN MovieHierarchy h ON m.episode_of_id = h.movie_id  -- Recursive join for episodes
)

SELECT
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    SUM(CASE WHEN m.production_year > 2010 THEN 1 ELSE 0 END) AS movies_post_2010,
    STRING_AGG(DISTINCT t.title, ', ') AS movie_titles,
    tt.kind AS title_kind,
    COALESCE(AVG(CASE WHEN c.note IS NOT NULL THEN c.nr_order END), 0) AS avg_order
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    MovieHierarchy mh ON c.movie_id = mh.movie_id
JOIN
    title t ON mh.movie_id = t.id
LEFT JOIN
    kind_type tt ON t.kind_id = tt.id
WHERE
    a.name IS NOT NULL
    AND a.name <> ''
GROUP BY
    a.name, tt.kind
HAVING
    COUNT(DISTINCT c.movie_id) > 5  -- Actors with more than 5 distinct movies
ORDER BY
    total_movies DESC,
    actor_name ASC;
