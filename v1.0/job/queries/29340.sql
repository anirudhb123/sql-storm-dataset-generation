
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank_year
    FROM
        aka_title t
    JOIN
        movie_info mi ON t.id = mi.movie_id
    WHERE
        mi.info LIKE '%Oscar%'
),
CombinedCast AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(p.name, ', ' ORDER BY p.name) AS cast_names
    FROM
        cast_info c
    JOIN
        aka_name p ON c.person_id = p.person_id
    GROUP BY
        c.movie_id
),
KeywordStats AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS total_keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    COALESCE(cc.total_cast, 0) AS total_cast,
    COALESCE(cc.cast_names, '') AS cast_names,
    COALESCE(ks.total_keywords, 0) AS total_keywords
FROM
    RankedMovies rm
LEFT JOIN
    CombinedCast cc ON rm.movie_id = cc.movie_id
LEFT JOIN
    KeywordStats ks ON rm.movie_id = ks.movie_id
WHERE
    rm.rank_year <= 5 
ORDER BY
    rm.production_year DESC, cc.total_cast DESC, rm.movie_title;
