
WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    WHERE
        t.production_year >= 2000
        AND k.keyword IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
role_summaries AS (
    SELECT
        ci.movie_id,
        r.role,
        COUNT(ci.id) AS count
    FROM
        cast_info ci
    JOIN
        role_type r ON ci.role_id = r.id
    GROUP BY
        ci.movie_id, r.role
),
detailed_report AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.company_names,
        md.actor_names,
        COALESCE(rs.role, 'Unknown Role') AS role,
        COALESCE(rs.count, 0) AS actor_count
    FROM
        movie_details md
    LEFT JOIN
        role_summaries rs ON md.movie_id = rs.movie_id
)
SELECT
    movie_id,
    title,
    production_year,
    keywords,
    company_names,
    actor_names,
    role,
    actor_count
FROM
    detailed_report
ORDER BY
    production_year DESC, title;
