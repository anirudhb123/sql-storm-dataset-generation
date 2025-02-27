WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, title.title, 1 AS level
    FROM aka_title title
    JOIN movie_link ml ON title.id = ml.movie_id
    JOIN title m ON ml.linked_movie_id = m.id
    WHERE title.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT ml.linked_movie_id, m.title, mh.level + 1
    FROM movie_hierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN title m ON ml.linked_movie_id = m.id
),
cast_and_info AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_actors
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE a.name IS NOT NULL
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    cai.actor_name,
    cai.actor_rank,
    cai.total_actors,
    COALESCE(mk.keywords, 'No keywords') AS keyword_list,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = mh.movie_id) AS company_count
FROM movie_hierarchy mh
LEFT JOIN cast_and_info cai ON mh.movie_id = cai.movie_id
LEFT JOIN movie_keywords mk ON mh.movie_id = mk.movie_id
ORDER BY mh.movie_id, cai.actor_rank;
