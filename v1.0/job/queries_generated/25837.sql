WITH indexed_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        LEFT(t.title, 10) AS title_prefix,
        k.keyword AS associated_keyword
    FROM
        title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
),
cast_info_summary AS (
    SELECT
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM
        cast_info ci
    JOIN
        role_type r ON ci.role_id = r.id
    GROUP BY
        ci.movie_id
),
company_info AS (
    SELECT
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies_involved,
        ARRAY_AGG(DISTINCT ct.kind) AS company_types
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
    it.title, 
    it.production_year,
    c.total_cast,
    c.roles,
    ci.companies_involved,
    ci.company_types,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    CONCAT(it.title_prefix, '...', COUNT(DISTINCT mk.keyword_id)) AS title_with_keyword_count
FROM
    indexed_titles it
JOIN
    cast_info_summary c ON it.title_id = c.movie_id
JOIN
    company_info ci ON it.title_id = ci.movie_id
LEFT JOIN
    movie_keyword mk ON it.title_id = mk.movie_id
GROUP BY
    it.title, it.production_year, c.total_cast, c.roles, ci.companies_involved, ci.company_types, it.title_prefix
ORDER BY
    it.production_year DESC,
    keyword_count DESC;
