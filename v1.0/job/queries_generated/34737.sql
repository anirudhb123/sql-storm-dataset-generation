WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, COALESCE(mt.title, 'Unknown Title') AS title, mt.season_nr, mt.episode_nr, 1 AS level
    FROM aka_title mt
    LEFT JOIN movie_companies mc ON mt.movie_id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT mh.movie_id, COALESCE(mt.title, 'Unknown Title') AS title, mt.season_nr, mt.episode_nr, mh.level + 1
    FROM movie_hierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.movie_id
    WHERE mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv_series'))
),
cast_details AS (
    SELECT c.movie_id, a.name AS actor_name, 
           RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS rank_order
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE a.name IS NOT NULL
),
title_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        ti.info AS additional_info,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords
    FROM aka_title t
    LEFT JOIN movie_info mi ON t.movie_id = mi.movie_id
    LEFT JOIN info_type ti ON mi.info_type_id = ti.id
    LEFT JOIN movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, ti.info
)
SELECT 
    mh.title AS movie_title,
    mh.season_nr,
    mh.episode_nr,
    cd.actor_name,
    ti.additional_info,
    ti.keywords,
    COUNT(cd.actor_name) OVER (PARTITION BY mh.movie_id) AS total_cast_count,
    CASE 
        WHEN COUNT(cd.actor_name) OVER (PARTITION BY mh.movie_id) > 5 THEN 'Large Cast'
        WHEN COUNT(cd.actor_name) OVER (PARTITION BY mh.movie_id) BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM movie_hierarchy mh
LEFT JOIN cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN title_info ti ON mh.movie_id = ti.title_id
WHERE mh.level < 3
AND ti.keywords IS NOT NULL
ORDER BY mh.title, cd.rank_order;
