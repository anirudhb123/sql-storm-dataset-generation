WITH RankedTitles AS (
    SELECT
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) as rn
    FROM
        aka_title at
    WHERE
        at.production_year IS NOT NULL
        AND at.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv_series'))
),
TopRatedMovies AS (
    SELECT
        mt.title,
        mt.production_year,
        AVG(CASE WHEN CAST(ci.person_role_id AS TEXT) IS NOT NULL THEN 1 ELSE 0 END) as average_roles
    FROM
        movie_info mi
    JOIN
        title mt ON mi.movie_id = mt.id
    JOIN
        complete_cast cc ON mt.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY
        mt.title, mt.production_year
    HAVING
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE NULL END) > 0.5
),
MovieCompanies AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
)
SELECT
    rt.title,
    rt.production_year,
    COALESCE(mv.company_names, 'No Companies') AS companies,
    COALESCE(trm.average_roles, 0) AS avg_roles
FROM
    RankedTitles rt
LEFT JOIN
    MovieCompanies mv ON rt.title = mv.movie_id
LEFT JOIN
    TopRatedMovies trm ON rt.title = trm.title
WHERE
    rt.rn <= 10
ORDER BY
    rt.production_year DESC,
    rt.title DESC;
