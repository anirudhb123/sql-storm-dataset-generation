
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM
        title t
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY
        t.id, t.title, t.production_year, t.kind_id
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        kind_id
    FROM
        RankedMovies
    WHERE
        rank <= 10
)
SELECT
    tm.title AS Movie_Title,
    tm.production_year AS Production_Year,
    kt.kind AS Kind,
    LISTAGG(DISTINCT an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS Actors
FROM
    TopMovies tm
JOIN
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN
    aka_name an ON ci.person_id = an.person_id
JOIN
    kind_type kt ON tm.kind_id = kt.id
GROUP BY
    tm.movie_id, tm.title, tm.production_year, kt.kind
ORDER BY
    tm.production_year DESC, COUNT(DISTINCT an.name) DESC;
