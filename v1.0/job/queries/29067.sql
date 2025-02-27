
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS all_actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS movie_keywords
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    LEFT JOIN
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        cast_count,
        all_actors,
        movie_keywords,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM
        RankedMovies
)
SELECT
    tm.rank,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.all_actors,
    COALESCE(tm.movie_keywords, 'No keywords found') AS movie_keywords,
    CASE
        WHEN mc.company_id IS NOT NULL THEN CONCAT('Produced by ', cp.name)
        ELSE 'Independently produced'
    END AS production_info
FROM
    TopMovies tm
LEFT JOIN
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN
    company_name cp ON mc.company_id = cp.id
LEFT JOIN
    company_type ct ON mc.company_type_id = ct.id
WHERE
    tm.rank <= 10
ORDER BY
    tm.rank;
