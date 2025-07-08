
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.imdb_index,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names
    FROM
        aka_title AS t
    JOIN
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN
        cast_info AS ci ON cc.subject_id = ci.person_id
    JOIN
        movie_companies AS mc ON mc.movie_id = t.id
    JOIN
        company_name AS cn ON mc.company_id = cn.id
    LEFT JOIN
        aka_name AS ak ON ak.person_id = ci.person_id
    GROUP BY
        t.id, t.title, t.production_year, t.imdb_index
),
TopRankedMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        imdb_index,
        total_cast,
        company_names,
        aka_names,
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM
        RankedMovies
)
SELECT
    rank,
    title,
    production_year,
    imdb_index,
    total_cast,
    company_names,
    aka_names
FROM
    TopRankedMovies
WHERE
    rank <= 10
ORDER BY
    rank;
