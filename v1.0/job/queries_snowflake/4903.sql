
WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.id = c.movie_id
    GROUP BY
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year
    FROM
        RankedMovies
    WHERE
        rank <= 5
),
MovieKeywordCounts AS (
    SELECT
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        TopMovies m ON mk.movie_id = m.movie_id
    GROUP BY
        m.movie_id
)
SELECT
    tm.title,
    tm.production_year,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    COALESCE(ARRAY_AGG(DISTINCT k.keyword) || 'No Keywords') AS keywords,
    c.kind AS company_type
FROM
    TopMovies tm
LEFT JOIN
    MovieKeywordCounts mkc ON tm.movie_id = mkc.movie_id
LEFT JOIN
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN
    company_type c ON mc.company_type_id = c.id
LEFT JOIN
    movie_info mi ON tm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
LEFT JOIN
    movie_link ml ON tm.movie_id = ml.movie_id
LEFT JOIN
    keyword k ON mkc.movie_id = k.id
WHERE
    (tm.production_year BETWEEN 2000 AND 2023 OR tm.production_year IS NULL)
GROUP BY
    tm.title, tm.production_year, mkc.keyword_count, c.kind
ORDER BY
    tm.production_year DESC, keyword_count DESC;
