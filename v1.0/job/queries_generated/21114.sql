WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rn
    FROM title t
),
company_joined AS (
    SELECT
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY c.name) AS company_rn
    FROM movie_companies m
    JOIN company_name c ON m.company_id = c.id
    JOIN company_type ct ON m.company_type_id = ct.id
),
cast_roles AS (
    SELECT
        ci.movie_id,
        r.role,
        COUNT(ci.person_id) AS actor_count
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY ci.movie_id, r.role
),
title_cast AS (
    SELECT
        rt.title_id,
        rt.title,
        rt.production_year,
        c.actor_count,
        COALESCE(cc.company_name, 'Unknown') AS company_name
    FROM ranked_titles rt
    LEFT JOIN cast_roles c ON rt.title_id = c.movie_id
    LEFT JOIN company_joined cc ON rt.title_id = cc.movie_id AND cc.company_rn = 1
)
SELECT
    tc.title,
    tc.production_year,
    tc.actor_count,
    tc.company_name,
    COALESCE(SUM(wp.movie_rating), 0) AS total_ratings,
    AVG(wp.movie_rating) AS avg_rating
FROM title_cast tc
LEFT JOIN (
    SELECT
        movie_id,
        rating AS movie_rating
    FROM movie_info
    WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
) AS wp ON tc.title_id = wp.movie_id
GROUP BY
    tc.title_id,
    tc.title,
    tc.production_year,
    tc.actor_count,
    tc.company_name
HAVING
    COUNT(tc.actor_count) IS NOT NULL
    AND AVG(wp.movie_rating) IS NOT NULL
ORDER BY
    tc.production_year DESC,
    tc.title ASC
OFFSET 10 ROWS;
