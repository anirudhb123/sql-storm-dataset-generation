WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
TopActors AS (
    SELECT
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY
        a.person_id, a.name
    HAVING
        COUNT(DISTINCT ci.movie_id) >= 5
),
MovieCompaniesInfo AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
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
    rt.title,
    rt.production_year,
    ta.name AS top_actor,
    mi.company_names,
    mi.company_types
FROM
    RankedTitles rt
LEFT JOIN
    TopActors ta ON rt.title_id = (SELECT ci.movie_id FROM cast_info ci WHERE ci.person_id = ta.person_id LIMIT 1)
LEFT JOIN
    MovieCompaniesInfo mi ON rt.title_id = mi.movie_id
WHERE
    rt.title_rank <= 10
ORDER BY
    rt.production_year DESC, rt.title;
