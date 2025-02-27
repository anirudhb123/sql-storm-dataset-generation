WITH RECURSIVE movie_hierarchy AS (
    SELECT title.id AS movie_id,
           title.title,
           title.production_year,
           title.kind_id,
           movie_link.linked_movie_id,
           1 AS level
    FROM title
    LEFT JOIN movie_link ON title.id = movie_link.movie_id
    WHERE title.production_year >= 2000
    UNION ALL
    SELECT mh.movie_id,
           t.title,
           t.production_year,
           t.kind_id,
           ml.linked_movie_id,
           mh.level + 1
    FROM movie_hierarchy mh
    JOIN movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN title t ON ml.linked_movie_id = t.id
    WHERE mh.level < 5
),
cast_and_role AS (
    SELECT ci.movie_id,
           ak.name AS actor_name,
           rt.role,
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS actor_order
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rt ON ci.role_id = rt.id
    WHERE ak.name IS NOT NULL
),
movie_keywords AS (
    SELECT mk.movie_id,
           string_agg(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_details AS (
    SELECT mh.movie_id,
           mh.title,
           mh.production_year,
           ca.actor_name,
           ca.role,
           COALESCE(mk.keywords, 'No Keywords') AS keywords,
           mh.level
    FROM movie_hierarchy mh
    LEFT JOIN cast_and_role ca ON mh.movie_id = ca.movie_id
    LEFT JOIN movie_keywords mk ON mh.movie_id = mk.movie_id
)
SELECT md.title,
       md.production_year,
       md.actor_name,
       md.role,
       md.keywords,
       md.level,
       COUNT(*) OVER (PARTITION BY md.movie_id) AS actor_count,
       CASE 
           WHEN md.level > 3 THEN 'Deeply Linked'
           ELSE 'Shallow Linked' 
       END AS link_depth
FROM movie_details md
WHERE md.level BETWEEN 1 AND 3
   OR (md.keywords IS NOT NULL AND md.keywords <> 'No Keywords')
ORDER BY md.production_year DESC, md.level, md.actor_name
OFFSET 5 ROWS FETCH NEXT 15 ROWS ONLY;
