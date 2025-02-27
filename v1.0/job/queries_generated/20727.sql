WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) as rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT
        ci.movie_id,
        ci.role_id,
        rt.role,
        COUNT(*) AS role_count
    FROM
        cast_info ci
    JOIN
        role_type rt ON ci.role_id = rt.id
    GROUP BY
        ci.movie_id, ci.role_id, rt.role
),
MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        co.name AS company_name,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        CASE 
            WHEN m.production_year < 2000 THEN 'Classic'
            WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern Era'
            ELSE 'Recent'
        END AS era
    FROM
        aka_title m
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        company_name co ON mc.company_id = co.id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        co.country_code IS NOT NULL
    GROUP BY
        m.id, m.title, m.production_year, co.name
    HAVING
        COUNT(DISTINCT k.id) > 3
),
FinalOutput AS (
    SELECT
        md.title,
        md.production_year,
        md.company_name,
        md.keywords,
        md.era,
        CAST(COALESCE(c.role_count, 0) AS integer) AS total_roles,
        STRING_AGG(DISTINCT cr.role, ', ') AS aggregated_roles
    FROM
        MovieDetails md
    LEFT JOIN
        CastRoles cr ON md.movie_id = cr.movie_id
    LEFT JOIN
        (
            SELECT
                movie_id,
                COUNT(DISTINCT person_id) AS role_count
            FROM
                cast_info
            GROUP BY
                movie_id
        ) c ON md.movie_id = c.movie_id
    WHERE
        md.era = 'Recent' AND md.production_year IS NOT NULL
    GROUP BY
        md.title, md.production_year, md.company_name, md.keywords, md.era
    HAVING
        COUNT(DISTINCT cr.role_id) FILTER (WHERE cr.role IS NOT NULL) > 1
)
SELECT
    title,
    production_year,
    company_name,
    keywords,
    era,
    total_roles,
    aggregated_roles
FROM
    FinalOutput
WHERE
    total_roles > 2
ORDER BY
    production_year DESC,
    title ASC
LIMIT 10;
