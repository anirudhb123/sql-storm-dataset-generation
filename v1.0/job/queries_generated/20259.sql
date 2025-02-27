WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS level
    FROM aka_title m
    WHERE m.production_year >= 2000
    UNION ALL
    SELECT m.id, m.title, m.production_year, mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.movie_id
    JOIN movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
), 
actor_info AS (
    SELECT 
        ka.person_id,
        ka.name,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        STRING_AGG(DISTINCT a.title, ', ') AS movies_list
    FROM aka_name ka
    JOIN cast_info ci ON ka.person_id = ci.person_id
    JOIN aka_title a ON ci.movie_id = a.id
    WHERE ka.name IS NOT NULL 
    GROUP BY ka.person_id, ka.name
), 
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT
    a.name AS actor_name,
    a.total_movies,
    a.movies_list,
    mk.keywords,
    COALESCE(mh.level, 0) AS movie_level,
    COUNT(DISTINCT ci2.movie_id) FILTER (WHERE ci2.nr_order <= 3) AS top_cast_movies
FROM actor_info a
LEFT JOIN movie_keywords mk ON a.total_movies > 5 AND mk.movie_id IN (
    SELECT c.movie_id 
    FROM cast_info c 
    WHERE c.person_id = a.person_id
)
LEFT JOIN movie_hierarchy mh ON mh.movie_id IN (
    SELECT DISTINCT ci.movie_id 
    FROM cast_info ci 
    WHERE ci.person_id = a.person_id
)
LEFT JOIN cast_info ci2 ON a.person_id = ci2.person_id
GROUP BY a.person_id, a.name, mk.keywords, mh.level
HAVING a.total_movies > 10
ORDER BY a.total_movies DESC, actor_name ASC;
