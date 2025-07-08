
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.id) AS rank,
        COALESCE(MAX(ki.keyword), 'No Keywords') AS primary_keyword
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY
        t.id, t.title, t.production_year
),
ActorRoles AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT CONCAT(n.name, ' as ', rt.role), ', ') AS roles,
        SUM(CASE WHEN rt.role LIKE '%lead%' THEN 1 ELSE 0 END) AS lead_roles
    FROM
        cast_info c
    JOIN
        name n ON c.person_id = n.id
    JOIN
        role_type rt ON c.role_id = rt.id
    GROUP BY
        c.movie_id
),
MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        COALESCE(mci.actor_count, 0) AS actor_count,
        mci.roles,
        mci.lead_roles,
        COALESCE(ci.name, 'Unknown Company') AS production_company
    FROM
        aka_title t
    LEFT JOIN
        ActorRoles mci ON t.id = mci.movie_id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name ci ON mc.company_id = ci.id
    WHERE
        ci.name IS NOT NULL OR mc.note IS NULL
)
SELECT
    d.movie_id,
    d.title,
    d.actor_count,
    d.roles,
    d.lead_roles,
    r.primary_keyword,
    CASE
        WHEN d.production_company = 'Unknown Company' THEN 'Independent'
        ELSE d.production_company
    END AS final_company,
    CASE
        WHEN d.lead_roles > 0 THEN 'Featured'
        ELSE 'Supporting'
    END AS cast_type
FROM
    MovieDetails d
JOIN
    RankedMovies r ON d.movie_id = r.movie_id
WHERE
    (d.actor_count > 0 OR r.primary_keyword = 'No Keywords')
    AND r.rank <= 5
ORDER BY
    d.actor_count DESC, d.title;
