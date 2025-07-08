
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM
        aka_title t
    WHERE
        t.production_year BETWEEN 2000 AND 2023
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.movie_title,
        rm.production_year
    FROM
        RankedMovies rm
    WHERE
        rm.rank <= 5
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
CastInfo AS (
    SELECT
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_cast,
        SUM(CASE WHEN p.gender = 'M' THEN 1 ELSE 0 END) AS male_cast
    FROM
        cast_info ci
    JOIN
        name p ON ci.person_id = p.id
    GROUP BY
        ci.movie_id
)
SELECT
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    mk.keywords,
    ci.total_cast,
    ci.female_cast,
    ci.male_cast,
    COALESCE(NULLIF(ci.total_cast, 0), NULL) AS safe_total_cast
FROM
    TopMovies tm
LEFT JOIN
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN
    CastInfo ci ON tm.movie_id = ci.movie_id
ORDER BY
    tm.production_year DESC, tm.movie_title;
