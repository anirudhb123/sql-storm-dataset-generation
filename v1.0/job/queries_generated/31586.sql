WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 0 AS level
    FROM aka_title m
    WHERE m.production_year >= 2000
    UNION ALL
    SELECT m.id, m.title, m.production_year, mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE mh.level < 3
),
cast_ranked AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM cast_info c
    JOIN aka_name a ON a.person_id = c.person_id
),
keyword_count AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_total
    FROM movie_keyword mk
    JOIN aka_title m ON mk.movie_id = m.id
    GROUP BY m.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cr.actor_count, 0) AS actor_count,
    COALESCE(kc.keyword_total, 0) AS keyword_total,
    CASE 
        WHEN kc.keyword_total > 5 THEN 'Highly Tagged'
        WHEN kc.keyword_total BETWEEN 2 AND 5 THEN 'Moderately Tagged'
        ELSE 'Sparsely Tagged'
    END AS tag_level,
    STRING_AGG(cr.actor_name, ', ') AS actor_names
FROM movie_hierarchy mh
LEFT JOIN (
    SELECT 
        movie_id,
        COUNT(*) AS actor_count
    FROM cast_ranked
    GROUP BY movie_id
) cr ON mh.movie_id = cr.movie_id
LEFT JOIN keyword_count kc ON mh.movie_id = kc.movie_id
GROUP BY mh.movie_id, mh.title, mh.production_year, cr.actor_count, kc.keyword_total
ORDER BY mh.production_year DESC, mh.title;
