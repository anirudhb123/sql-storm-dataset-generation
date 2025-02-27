WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM title m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT 
        mm.id AS movie_id,
        mm.title AS movie_title,
        mm.production_year,
        mh.level + 1
    FROM title mm
    JOIN movie_link ml ON mm.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE mh.level < 5
),
highest_grossing AS (
    SELECT 
        title.title AS movie_title,
        SUM(movi_info.info::numeric) AS total_gross
    FROM title
    JOIN movie_info movi_info ON title.id = movi_info.movie_id 
    WHERE movi_info.info_type_id = (SELECT id FROM info_type WHERE info='Gross')
    GROUP BY title.title
    ORDER BY total_gross DESC
    LIMIT 10
),
cast_summary AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
),
title_with_cast AS (
    SELECT 
        t.title,
        COALESCE(cs.actor_name, 'No Actor') AS actor_name,
        cs.actor_rank
    FROM title t
    LEFT JOIN cast_summary cs ON t.id = cs.movie_id
),
keyword_summary AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mt
    JOIN keyword k ON mt.keyword_id = k.id
    GROUP BY mt.movie_id
)
SELECT 
    mh.movie_title,
    mh.production_year,
    twc.actor_name,
    kc.keywords,
    hg.total_gross
FROM movie_hierarchy mh
LEFT JOIN title_with_cast twc ON mh.movie_id = twc.movie_id
LEFT JOIN keyword_summary kc ON mh.movie_id = kc.movie_id
LEFT JOIN highest_grossing hg ON mh.movie_title = hg.movie_title
WHERE mh.level = 1
ORDER BY hg.total_gross DESC NULLS LAST;
