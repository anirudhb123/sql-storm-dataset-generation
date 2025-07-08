
WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
cast_roles AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT CONCAT(a.name, ' (', r.role, ')'), ', ') WITHIN GROUP (ORDER BY a.name) AS cast_members
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.movie_id
),
company_movies AS (
    SELECT
        m.movie_id,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS company_names
    FROM
        movie_companies m
    JOIN
        company_name co ON m.company_id = co.id
    GROUP BY
        m.movie_id
)
SELECT
    rt.title,
    rt.production_year,
    cr.total_cast,
    cr.cast_members,
    cm.company_names,
    CASE 
        WHEN rt.production_year < 2000 THEN 'Classic'
        WHEN rt.production_year BETWEEN 2000 AND 2010 THEN 'Modern Classic'
        ELSE 'Recent'
    END AS era_label
FROM
    ranked_titles rt
LEFT JOIN
    cast_roles cr ON rt.title_id = cr.movie_id
LEFT JOIN
    company_movies cm ON rt.title_id = cm.movie_id
WHERE
    rt.title_rank <= 5
ORDER BY
    rt.production_year DESC,
    rt.title;
