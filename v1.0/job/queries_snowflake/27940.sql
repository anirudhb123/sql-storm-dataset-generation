
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS all_actor_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS all_keywords,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank_by_cast
    FROM
        aka_title AS t
    LEFT JOIN
        cast_info AS ci ON t.id = ci.movie_id
    LEFT JOIN
        aka_name AS ak ON ak.person_id = ci.person_id
    LEFT JOIN
        movie_keyword AS mk ON mk.movie_id = t.id
    LEFT JOIN
        keyword AS k ON k.id = mk.keyword_id
    GROUP BY
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        cast_count,
        all_actor_names,
        all_keywords,
        rank_by_cast
    FROM
        RankedMovies
    WHERE
        rank_by_cast <= 3
)
SELECT
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.all_actor_names,
    tm.all_keywords,
    COALESCE(ct.kind, 'Unknown') AS company_type
FROM
    TopMovies AS tm
LEFT JOIN
    movie_companies AS mc ON mc.movie_id = tm.movie_id
LEFT JOIN
    company_type AS ct ON mc.company_type_id = ct.id
ORDER BY
    tm.production_year DESC, tm.cast_count DESC;
