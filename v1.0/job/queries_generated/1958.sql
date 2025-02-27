WITH MovieRankings AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.title, t.production_year
),
TopMovies AS (
    SELECT
        title,
        production_year
    FROM
        MovieRankings
    WHERE
        rank <= 5
),
KeywordCounts AS (
    SELECT
        t.title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY
        t.title
)
SELECT
    tm.title,
    tm.production_year,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN kc.keyword_count IS NULL THEN 'No Keywords'
        ELSE 'Has Keywords'
    END AS keyword_status
FROM
    TopMovies tm
LEFT JOIN
    KeywordCounts kc ON tm.title = kc.title
ORDER BY
    tm.production_year DESC, keyword_count DESC;
