WITH RECURSIVE genre_hierarchy AS (
    SELECT id, kind FROM kind_type
    UNION ALL
    SELECT kt.id, CONCAT('Sub-', kt.kind) 
    FROM kind_type kt 
    JOIN genre_hierarchy gh ON kt.id = gh.id + 1 
    WHERE kt.kind IS NOT NULL
),
popular_movies AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        COALESCE(SUM(mk.count), 0) AS popularity_score,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY COALESCE(SUM(mk.count), 0) DESC) AS rn
    FROM
        aka_title mt
    LEFT JOIN (
        SELECT
            movie_id,
            COUNT(*) AS count
        FROM
            movie_keyword
        GROUP BY
            movie_id
    ) mk ON mt.id = mk.movie_id
    WHERE
        mt.production_year IS NOT NULL
    GROUP BY
        mt.id, mt.title
),
movie_roles AS (
    SELECT
        cm.movie_id,
        cp.person_id,
        cr.role AS person_role,
        ROW_NUMBER() OVER (PARTITION BY cm.movie_id ORDER BY cr.role) AS role_order
    FROM
        cast_info cm
    JOIN role_type cr ON cm.role_id = cr.id
    JOIN person_info cp ON cm.person_id = cp.person_id
    WHERE
        cr.role IS NOT NULL AND cp.info IS NOT NULL
),
final_results AS (
    SELECT
        pm.movie_title,
        gh.kind AS genre,
        mr.person_role,
        COALESCE(mr.role_order, 0) AS role_order,
        COALESCE(pm.popularity_score, 0) AS popularity 
    FROM
        popular_movies pm
    LEFT JOIN genre_hierarchy gh ON pm.movie_id = gh.id
    LEFT JOIN movie_roles mr ON pm.movie_id = mr.movie_id
    WHERE
        pm.rn = 1 
        AND (pm.popularity_score IS NOT NULL OR mr.person_role IS NOT NULL)
)
SELECT
    fr.movie_title,
    fr.genre,
    COUNT(fr.person_role) AS total_roles,
    MAX(fr.role_order) AS highest_role_order,
    STRING_AGG(DISTINCT fr.person_role, ', ') AS roles
FROM
    final_results fr
GROUP BY 
    fr.movie_title, fr.genre
HAVING 
    COUNT(fr.person_role) > 1 
    AND MAX(fr.role_order) > 0
ORDER BY 
    fr.movie_title;
