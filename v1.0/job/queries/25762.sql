WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors_names,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title a
    LEFT JOIN
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY
        a.id, a.title, a.production_year
),
KeywordMovies AS (
    SELECT
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS movie_keywords
    FROM
        movie_keyword m
    JOIN
        keyword k ON m.keyword_id = k.id
    GROUP BY
        m.movie_id
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.actors_names,
    km.movie_keywords
FROM
    RankedMovies rm
LEFT JOIN
    KeywordMovies km ON rm.movie_id = km.movie_id
WHERE
    rm.production_year BETWEEN 2000 AND 2020
ORDER BY
    rm.rank,
    rm.production_year DESC;
