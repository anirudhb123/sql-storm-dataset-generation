WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CompanySummary AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    GROUP BY
        mc.movie_id
),
CastDetails AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    GROUP BY
        ci.movie_id
),
MovieInfo AS (
    SELECT
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Genre' THEN mi.info END) AS genre_info,
        MAX(CASE WHEN it.info = 'Awards' THEN mi.info END) AS awards_info
    FROM
        movie_info mi
    JOIN
        info_type it ON mi.info_type_id = it.id
    GROUP BY
        mi.movie_id
)

SELECT
    tt.title,
    tt.production_year,
    cs.company_count,
    cs.company_names,
    cd.actor_count,
    cd.actor_names,
    mi.genre_info,
    mi.awards_info
FROM
    RankedTitles tt
LEFT JOIN
    CompanySummary cs ON tt.title_id = cs.movie_id
LEFT JOIN
    CastDetails cd ON tt.title_id = cd.movie_id
LEFT JOIN
    MovieInfo mi ON tt.title_id = mi.movie_id
WHERE
    (tt.production_year > 2000 OR mi.genre_info IS NULL)
    AND (cd.actor_count IS NULL OR cd.actor_count >= 5)
ORDER BY
    tt.production_year DESC,
    tt.title_rank;

