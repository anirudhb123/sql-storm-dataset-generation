WITH RankedTitles AS (
    SELECT
        t.id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
MovieCompanies AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        movie_companies mc
    GROUP BY
        mc.movie_id
),
PersonRoles AS (
    SELECT
        ci.movie_id,
        ci.person_id,
        ct.kind AS role,
        COUNT(*) AS role_count
    FROM
        cast_info ci
    JOIN
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY
        ci.movie_id, ci.person_id, ct.kind
)
SELECT
    titles.title,
    titles.production_year,
    COALESCE(companies.company_count, 0) AS total_companies,
    COALESCE(roles.role_count, 0) AS total_roles,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = titles.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'BoxOffice')) AS box_office_info_count,
    CASE
        WHEN roles.role IS NULL THEN 'No Role Assigned'
        ELSE roles.role
    END AS role_description
FROM
    RankedTitles titles
LEFT JOIN
    MovieCompanies companies ON titles.id = companies.movie_id
LEFT JOIN
    PersonRoles roles ON titles.id = roles.movie_id
WHERE
    titles.rank <= 5
ORDER BY
    titles.production_year DESC, titles.title ASC;
