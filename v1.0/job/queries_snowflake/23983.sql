
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast_count
    FROM
        aka_title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY
        t.id, t.title, t.production_year
),

DistinctKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),

HighRatedMovies AS (
    SELECT
        r.movie_id,
        r.title,
        r.production_year,
        rk.keywords,
        COALESCE(mi.info, 'No info available') AS movie_info
    FROM
        RankedMovies r
    LEFT JOIN
        movie_info mi ON r.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating' LIMIT 1)
    LEFT JOIN
        DistinctKeywords rk ON r.movie_id = rk.movie_id
    WHERE
        r.rank_by_cast_count <= 10
),

MovieCompanies AS (
    SELECT
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        movie_companies mc
    JOIN
        aka_title m ON mc.movie_id = m.id
    GROUP BY
        m.movie_id
    HAVING
        COUNT(DISTINCT mc.company_id) > 2
)

SELECT
    h.title,
    h.production_year,
    h.keywords,
    h.movie_info,
    COALESCE(c.company_count, 0) AS company_count
FROM
    HighRatedMovies h
LEFT JOIN
    MovieCompanies c ON h.movie_id = c.movie_id
WHERE
    h.production_year BETWEEN 2000 AND 2023
ORDER BY
    h.production_year DESC,
    h.movie_info DESC NULLS LAST;
