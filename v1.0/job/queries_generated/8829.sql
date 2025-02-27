WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, 1 AS level
    FROM title m
    WHERE m.production_year >= 2000
    UNION ALL
    SELECT m.id AS movie_id, m.title, mh.level + 1
    FROM movie_link ml
    JOIN title m ON ml.linked_movie_id = m.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE mh.level < 5
), 
cast_details AS (
    SELECT c.id, c.movie_id, a.name AS actor_name, r.role, t.production_year
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    JOIN title t ON c.movie_id = t.id
    WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
), 
company_details AS (
    SELECT mc.movie_id, cn.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
), 
movie_performance AS (
    SELECT mh.title, mh.level, cd.actor_name, cd.role, cd.production_year, 
           COUNT(DISTINCT cd.movie_id) OVER (PARTITION BY mh.movie_id) AS total_actors, 
           COUNT(DISTINCT co.company_name) OVER (PARTITION BY mh.movie_id) AS total_companies
    FROM movie_hierarchy mh
    LEFT JOIN cast_details cd ON mh.movie_id = cd.movie_id
    LEFT JOIN company_details co ON mh.movie_id = co.movie_id
)
SELECT title, level, actor_name, role, production_year, total_actors, total_companies
FROM movie_performance
ORDER BY level DESC, title;
