WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS title_id,
        title,
        kind_id,
        production_year,
        md5sum,
        1 AS level
    FROM title mt
    WHERE production_year IS NOT NULL

    UNION ALL

    SELECT 
        mt.id AS title_id,
        mt.title,
        mt.kind_id,
        mt.production_year,
        mt.md5sum,
        mh.level + 1
    FROM title mt
    JOIN movie_link ml ON mt.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.title_id
),
coefficient AS (
    SELECT 
        MAX(cast_info.nr_order) AS max_order,
        AVG(COALESCE(person_info.info, '0')::integer) AS average_score
    FROM cast_info
    LEFT JOIN person_info ON cast_info.person_id = person_info.person_id
    GROUP BY cast_info.movie_id
),
filtered_titles AS (
    SELECT 
        t.id,
        t.title,
        t.production_year,
        COALESCE(mt.md5sum, 'unknown') AS md5sum,
        CASE 
            WHEN mt.production_year IS NOT NULL THEN 'Produced'
            ELSE 'Not Produced'
        END AS production_status
    FROM title t
    LEFT JOIN movie_info m ON t.id = m.movie_id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN movie_hierarchy mh ON t.id = mh.title_id
),
title_stats AS (
    SELECT 
        ft.id,
        ft.title,
        ft.production_year,
        ft.md5sum,
        ft.production_status,
        COUNT(*) FILTER (WHERE ci.role_id IS NOT NULL) AS number_of_actors,
        COUNT(DISTINCT ci.person_id) AS unique_actors,
        MAX(NVL(ci.nr_order, 0)) AS highest_order,
        ROUND(AVG(ci.nr_order), 2) AS avg_order
    FROM filtered_titles ft
    LEFT JOIN cast_info ci ON ft.id = ci.movie_id
    GROUP BY ft.id, ft.title, ft.production_year, ft.md5sum, ft.production_status
)
SELECT 
    ts.title,
    ts.production_year,
    ts.production_status,
    ts.number_of_actors,
    ts.unique_actors,
    ts.avg_order,
    COALESCE(ch.level, 0) AS hierarchy_level,
    CASE 
        WHEN ts.unique_actors > 5 AND ts.number_of_actors IS NOT NULL THEN 'Ensemble Cast'
        WHEN ts.number_of_actors IS NULL THEN 'No Actors'
        ELSE 'Standard Cast'
    END AS cast_type
FROM title_stats ts
LEFT JOIN movie_hierarchy ch ON ts.id = ch.title_id
ORDER BY 
    ts.production_year DESC NULLS LAST,
    ts.unique_actors DESC,
    ts.title;
