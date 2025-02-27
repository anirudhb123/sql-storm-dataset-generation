
WITH movie_title_info AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
        c.name AS company_name,
        STRING_AGG(DISTINCT a.name, ',') AS actors
    FROM
        aka_title AS m
    LEFT JOIN
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies AS mc ON m.id = mc.movie_id
    LEFT JOIN
        company_name AS c ON mc.company_id = c.id
    LEFT JOIN
        cast_info AS ci ON m.id = ci.movie_id
    LEFT JOIN
        aka_name AS a ON ci.person_id = a.person_id
    GROUP BY
        m.id, m.title, m.production_year, m.kind_id, c.name
),
role_summary AS (
    SELECT
        ci.movie_id,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM
        cast_info AS ci
    JOIN
        role_type AS rt ON ci.person_role_id = rt.id
    GROUP BY
        ci.movie_id, rt.role
)
SELECT
    mt.movie_id,
    mt.title,
    mt.production_year,
    mt.kind_id,
    mt.keywords,
    mt.company_name,
    mt.actors,
    rs.role,
    rs.role_count
FROM
    movie_title_info AS mt
LEFT JOIN
    role_summary AS rs ON mt.movie_id = rs.movie_id
ORDER BY
    mt.production_year DESC,
    mt.title;
