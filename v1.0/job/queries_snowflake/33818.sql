
WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year,  
           0 AS level
    FROM aka_title m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year,  
           mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE mh.level < 3
),

cast_details AS (
    SELECT ci.movie_id, 
           COUNT(*) AS cast_count,
           LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names
    FROM cast_info ci
    INNER JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY ci.movie_id
),

keyword_counts AS (
    SELECT mk.movie_id, 
           COUNT(*) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),

ranked_movies AS (
    SELECT mh.movie_id, 
           mh.title, 
           mh.production_year, 
           cd.cast_count, 
           kc.keyword_count,
           ROW_NUMBER() OVER (ORDER BY mh.production_year DESC, cd.cast_count DESC) AS rank
    FROM movie_hierarchy mh
    LEFT JOIN cast_details cd ON mh.movie_id = cd.movie_id
    LEFT JOIN keyword_counts kc ON mh.movie_id = kc.movie_id
)

SELECT rm.title, 
       rm.production_year, 
       COALESCE(rm.cast_count, 0) AS total_cast, 
       COALESCE(rm.keyword_count, 0) AS total_keywords, 
       rm.rank,
       (SELECT COUNT(DISTINCT c.id) 
        FROM complete_cast cc
        JOIN aka_title c ON cc.movie_id = c.id
        WHERE c.production_year = rm.production_year) AS movies_by_year
FROM ranked_movies rm
WHERE rm.rank <= 10
ORDER BY rm.rank;
