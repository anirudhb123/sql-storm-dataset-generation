WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast
    FROM
        aka_title m
    LEFT JOIN
        cast_info c ON m.id = c.movie_id
    GROUP BY
        m.id, m.title, m.production_year
),
HighRankedMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM
        RankedMovies rm
    WHERE
        rm.rank_by_cast <= 5
),
MovieCompanyInfo AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        MAX(ct.kind) AS company_type
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
    hm.title,
    hm.production_year,
    mci.company_names,
    COALESCE(NULLIF(mci.company_type, ''), 'N/A') AS company_type,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = hm.movie_id) AS keyword_count,
    (SELECT STRING_AGG(DISTINCT k.keyword, ', ') FROM movie_keyword mk JOIN keyword k ON mk.keyword_id = k.id WHERE mk.movie_id = hm.movie_id) AS keywords,
    (SELECT AVG(pi.info_type_id) FROM person_info pi JOIN cast_info ci ON pi.person_id = ci.person_id WHERE ci.movie_id = hm.movie_id) AS avg_info_type_id
FROM
    HighRankedMovies hm
LEFT JOIN
    MovieCompanyInfo mci ON hm.movie_id = mci.movie_id
ORDER BY
    hm.production_year DESC, hm.title;
