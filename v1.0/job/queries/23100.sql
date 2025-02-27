WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),

ActorRoles AS (
    SELECT
        c.person_id,
        r.role,
        COUNT(*) AS role_count
    FROM
        cast_info c
    JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.person_id, r.role
),

MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),

CompanyInfo AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
)

SELECT
    m.title,
    m.production_year,
    COALESCE(ar.role_count, 0) AS actor_role_count,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
    COALESCE(ci.company_count, 0) AS number_of_companies,
    COALESCE(ci.company_names, 'No Companies') AS companies_involved
FROM
    RankedMovies m
LEFT JOIN
    ActorRoles ar ON ar.person_id = (
        SELECT person_id
        FROM cast_info
        WHERE movie_id = m.movie_id
        ORDER BY nr_order
        LIMIT 1
    )
LEFT JOIN
    MovieKeywords mk ON m.movie_id = mk.movie_id
LEFT JOIN
    CompanyInfo ci ON m.movie_id = ci.movie_id
WHERE
    (m.rank BETWEEN 1 AND 10 OR m.production_year < 2000)
    AND (m.title ILIKE '%Mystery%' OR m.production_year IS NULL)
ORDER BY
    m.production_year DESC, m.title ASC;