WITH RankedTitles AS (
    SELECT
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year) AS year_rank,
        COUNT(*) OVER (PARTITION BY a.production_year) AS title_count
    FROM
        aka_title a
    WHERE
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorInfo AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        cast_info c
    INNER JOIN
        aka_name an ON c.person_id = an.person_id
    GROUP BY
        c.movie_id
),
MoviesWithCompanies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(SUM(mc.company_type_id), 0) AS company_types_count
    FROM
        title m
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY
        m.id
)
SELECT
    rt.title,
    rt.production_year,
    rt.title_count,
    ai.actor_count,
    mwc.company_types_count
FROM
    RankedTitles rt
LEFT JOIN
    ActorInfo ai ON rt.id = ai.movie_id
LEFT JOIN
    MoviesWithCompanies mwc ON rt.id = mwc.movie_id
WHERE
    rt.year_rank <= 5
ORDER BY
    rt.production_year DESC,
    title_count DESC,
    ai.actor_count ASC;
