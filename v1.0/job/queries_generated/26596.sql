WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM
        title t
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id
),
FilteredTitles AS (
    SELECT
        title_id,
        title,
        production_year,
        company_count,
        keyword_count,
        RANK() OVER (ORDER BY production_year DESC, keyword_count DESC) AS rank
    FROM
        RankedTitles
),
PersonTitleRoles AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        rt.role AS role_name
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        title t ON ci.movie_id = t.id
    JOIN
        role_type rt ON ci.role_id = rt.id
)
SELECT
    ft.title,
    ft.production_year,
    ft.company_count,
    ft.keyword_count,
    pt.actor_name,
    pt.role_name
FROM
    FilteredTitles ft
LEFT JOIN
    PersonTitleRoles pt ON ft.title_id = pt.movie_title
WHERE
    ft.rank <= 100
ORDER BY
    ft.production_year DESC, ft.keyword_count DESC, pt.actor_name;
