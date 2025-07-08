
WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS depth
    FROM aka_title m
    WHERE m.production_year >= 2000  
    UNION ALL
    SELECT m.id, m.title, m.production_year, mh.depth + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE mh.depth < 3  
),
actor_movies AS (
    SELECT ci.movie_id, COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    WHERE an.name IS NOT NULL 
    GROUP BY ci.movie_id
),
movie_keywords AS (
    SELECT mk.movie_id, LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    COALESCE(am.actor_count, 0) AS actor_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    ROW_NUMBER() OVER (ORDER BY h.production_year DESC, h.title) AS ranking
FROM movie_hierarchy h
LEFT JOIN actor_movies am ON h.movie_id = am.movie_id
LEFT JOIN movie_keywords mk ON h.movie_id = mk.movie_id
WHERE h.depth = 2 
  AND (h.production_year IS NOT NULL OR am.actor_count > 0) 
ORDER BY h.production_year DESC, h.title;
