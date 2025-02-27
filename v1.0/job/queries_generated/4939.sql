WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title m
    LEFT JOIN
        cast_info c ON m.id = c.movie_id
    GROUP BY
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast
    FROM
        RankedMovies rm
    WHERE
        rm.rank <= 5
)
SELECT
    tm.title,
    tm.production_year,
    co.name AS company_name,
    ct.kind AS company_type,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = tm.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')) AS rating_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM
    TopMovies tm
JOIN
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN
    company_name co ON mc.company_id = co.id
JOIN
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
WHERE
    co.country_code IS NOT NULL
GROUP BY
    tm.movie_id, tm.title, tm.production_year, co.name, ct.kind
ORDER BY
    tm.production_year DESC, tm.total_cast DESC;
