WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT
        c.person_id,
        c.role_id,
        COUNT(*) AS num_roles,
        MAX(CASE WHEN r.role IS NULL THEN 'Unknown' ELSE r.role END) AS role_name
    FROM
        cast_info c
    LEFT JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.person_id, c.role_id
),
CompanyTitles AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        SUM(CASE WHEN ct.kind = 'Production' THEN 1 ELSE 0 END) AS production_count
    FROM
        movie_companies mc
    INNER JOIN
        company_name cn ON mc.company_id = cn.id
    INNER JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
),
MovieKeywordStats AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        MAX(CASE WHEN k.keyword IS NULL THEN 'No Keyword' ELSE k.keyword END) AS sample_keyword
    FROM
        movie_keyword mk
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    t.title,
    t.production_year,
    co.company_names,
    a.num_roles,
    a.role_name,
    mk.keyword_count,
    mk.sample_keyword,
    CASE
        WHEN a.num_roles > 5 THEN 'Star'
        WHEN a.num_roles BETWEEN 3 AND 5 THEN 'Support'
        ELSE 'Extra'
    END AS actor_rank,
    NULLIF(t.title_rank, 0) AS title_rank
FROM
    RankedTitles t
LEFT JOIN
    ActorRoles a ON a.person_id = (
        SELECT c.person_id
        FROM cast_info c
        WHERE c.movie_id = t.title_id
        ORDER BY c.nr_order
        LIMIT 1
    )
LEFT JOIN
    CompanyTitles co ON co.movie_id = t.title_id
LEFT JOIN
    MovieKeywordStats mk ON mk.movie_id = t.title_id
WHERE
    (t.production_year >= 2000 OR t.production_year IS NULL)
    AND (a.role_name IS NOT NULL OR mk.keyword_count > 0)
ORDER BY
    t.production_year DESC,
    title_rank ASC
LIMIT 100;