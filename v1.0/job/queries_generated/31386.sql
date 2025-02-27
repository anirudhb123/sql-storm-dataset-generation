WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id, m.title, m.production_year, 1 AS level
    FROM aka_title m
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT m.id, m.title, m.production_year, mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.id
),
movie_academic AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(SUM(mi.info IS NOT NULL AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Academy Award')), 0) AS academy_award_count
    FROM aka_title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY m.id, m.title
),
cast_roles AS (
    SELECT 
        c.movie_id, 
        r.role, 
        COUNT(c.id) AS role_count
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id, r.role
),
weighted_movies AS (
    SELECT 
        mh.id, 
        mh.title, 
        mh.production_year,
        COALESCE(SUM(CASE WHEN ca.role = 'lead' THEN cr.role_count ELSE 0 END), 0) AS lead_role_weight,
        COALESCE(SUM(CASE WHEN ca.role = 'support' THEN cr.role_count ELSE 0 END), 0) AS support_role_weight,
        COALESCE(SUM(CASE WHEN ca.role IS NULL THEN cr.role_count ELSE 0 END), 0) AS other_role_weight
    FROM movie_hierarchy mh
    LEFT JOIN cast_roles cr ON mh.id = cr.movie_id
    LEFT JOIN role_type ca ON cr.role = ca.role
    GROUP BY mh.id, mh.title, mh.production_year
)
SELECT 
    wm.title,
    wm.production_year,
    wm.lead_role_weight,
    wm.support_role_weight,
    wm.other_role_weight,
    ma.academy_award_count,
    CASE 
        WHEN ma.academy_award_count > 0 THEN 'Award Winner'
        ELSE 'No Awards'
    END AS award_status
FROM weighted_movies wm
LEFT JOIN movie_academic ma ON wm.id = ma.movie_id
ORDER BY wm.production_year DESC, wm.lead_role_weight DESC;
