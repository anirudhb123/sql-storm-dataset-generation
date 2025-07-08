WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT a.name) AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_in_year
    FROM
        aka_title m
    JOIN
        complete_cast cc ON cc.movie_id = m.id
    JOIN
        cast_info c ON c.movie_id = m.id
    JOIN
        aka_name a ON a.person_id = c.person_id
    GROUP BY
        m.id, m.title, m.production_year
),
MovieKeywords AS (
    SELECT
        m.id AS movie_id,
        ARRAY_AGG(k.keyword) AS keywords
    FROM
        aka_title m
    JOIN
        movie_keyword mk ON mk.movie_id = m.id
    JOIN
        keyword k ON k.id = mk.keyword_id
    GROUP BY
        m.id
)
SELECT
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.total_cast,
    rm.cast_names,
    mk.keywords,
    rm.rank_in_year
FROM
    RankedMovies rm
LEFT JOIN
    MovieKeywords mk ON mk.movie_id = rm.movie_id
WHERE
    rm.rank_in_year <= 5
ORDER BY
    rm.production_year DESC, rm.total_cast DESC;
