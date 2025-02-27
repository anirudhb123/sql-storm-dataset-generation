WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 0 AS level
    FROM aka_title m
    WHERE m.production_year >= 2000
    
    UNION ALL
    
    SELECT m.id, m.title, m.production_year, mh.level + 1
    FROM aka_title m
    JOIN movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
cast_roles AS (
    SELECT ci.movie_id, ct.kind AS role_type, COUNT(ci.person_id) AS role_count
    FROM cast_info ci
    JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY ci.movie_id, ct.kind
),
title_keywords AS (
    SELECT mt.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mt
    JOIN keyword k ON mt.keyword_id = k.id
    GROUP BY mt.movie_id
),
movie_info_summary AS (
    SELECT mi.movie_id, 
           MAX(CASE WHEN it.info = 'Budget' THEN mi.info ELSE NULL END) AS budget,
           MAX(CASE WHEN it.info = 'Box Office' THEN mi.info ELSE NULL END) AS box_office
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
)

SELECT 
    mh.title,
    mh.production_year,
    COALESCE(ri.role_count, 0) AS total_cast,
    ki.keywords,
    COALESCE(mis.budget, 'N/A') AS budget,
    COALESCE(mis.box_office, 'N/A') AS box_office
FROM movie_hierarchy mh
LEFT JOIN cast_roles ri ON mh.movie_id = ri.movie_id
LEFT JOIN title_keywords ki ON mh.movie_id = ki.movie_id
LEFT JOIN movie_info_summary mis ON mh.movie_id = mis.movie_id
ORDER BY mh.production_year DESC, mh.title;
