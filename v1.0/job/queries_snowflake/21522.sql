
WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast_count
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.movie_id = c.movie_id
    WHERE
        a.production_year BETWEEN 1990 AND 2020
    GROUP BY
        a.id, a.title, a.production_year
),
HighCastMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM
        RankedMovies rm
    WHERE
        rm.rank_by_cast_count <= 5
),
MovieInfo AS (
    SELECT
        hcm.movie_id,
        LISTAGG(mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS movie_info
    FROM
        movie_info mi
    JOIN
        HighCastMovies hcm ON mi.movie_id = hcm.movie_id
    GROUP BY
        hcm.movie_id
),
CompanyStats AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        MAX(CASE WHEN comp.kind IS NULL THEN 'Unknown' ELSE comp.kind END) AS company_type
    FROM
        movie_companies mc
    LEFT JOIN
        company_type comp ON mc.company_type_id = comp.id
    GROUP BY
        mc.movie_id
)
SELECT
    hcm.movie_id,
    hcm.title,
    hcm.production_year,
    hcm.cast_count,
    mi.movie_info,
    cs.company_count,
    cs.company_type
FROM
    HighCastMovies hcm
LEFT JOIN
    MovieInfo mi ON hcm.movie_id = mi.movie_id
LEFT JOIN
    CompanyStats cs ON hcm.movie_id = cs.movie_id
WHERE
    cs.company_count IS NOT NULL
ORDER BY
    hcm.production_year DESC,
    hcm.cast_count DESC,
    hcm.title ASC;
