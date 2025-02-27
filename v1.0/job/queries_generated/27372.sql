WITH movie_details AS (
    SELECT
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.role_id) AS roles,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM
        title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
company_info AS (
    SELECT
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
)
SELECT
    md.movie_title,
    md.production_year,
    md.roles,
    md.keyword_count,
    ci.companies,
    ci.company_types
FROM
    movie_details md
JOIN
    company_info ci ON md.movie_id = ci.movie_id
WHERE
    md.production_year >= 2000
AND
    md.keyword_count > 5
ORDER BY
    md.production_year DESC, md.movie_title;
