WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id, m.title, m.production_year, 0 AS level
    FROM aka_title m
    WHERE m.production_year >= 2000
    UNION ALL
    SELECT m.id, m.title, m.production_year, mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.id
),
cast_details AS (
    SELECT c.movie_id, a.name AS actor_name, r.role AS role_name, 
           ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS role_rank
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    WHERE r.role IN ('Actor', 'Director') AND a.name IS NOT NULL
),
movie_category AS (
    SELECT kind_type.kind AS category, COUNT(*) AS film_count
    FROM aka_title t
    JOIN kind_type ON t.kind_id = kind_type.id
    GROUP BY kind_type.kind
),
filtered_movies AS (
    SELECT mh.id AS movie_id, mh.title, mh.production_year, COALESCE(md.info, 'No Info') AS additional_info
    FROM movie_hierarchy mh
    LEFT JOIN movie_info md ON mh.id = md.movie_id AND md.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
    WHERE mh.level < 3
),
ranked_movies AS (
    SELECT fp.movie_id, fp.title, fp.production_year, fc.actor_name, fc.role_name, 
           ROW_NUMBER() OVER (PARTITION BY fp.movie_id ORDER BY fc.role_rank) AS actor_order
    FROM filtered_movies fp
    LEFT JOIN cast_details fc ON fp.movie_id = fc.movie_id
)
SELECT r.movie_id, r.title, r.production_year, STRING_AGG(DISTINCT r.actor_name) AS actors,
       mt.category, (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = r.movie_id) AS keyword_count
FROM ranked_movies r
JOIN movie_category mt ON mt.film_count > 1
GROUP BY r.movie_id, r.title, r.production_year, mt.category
HAVING COUNT(DISTINCT r.actor_name) > 2 AND MIN(r.actor_order) = 1
ORDER BY COUNT(DISTINCT r.actor_name) DESC, r.production_year ASC
LIMIT 20;

-- Note: The query performs several complex aggregations and joins, and handles NULL logic 
-- with COALESCE, complex predicates in the HAVING clause, along with window functions 
-- to determine role rankings. The recursive CTE handles film relationships and links,
-- creating a multilevel film hierarchy while focusing on post-2000 productions.
