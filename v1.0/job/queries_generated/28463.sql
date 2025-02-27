WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM
        aka_title AS a
    JOIN
        movie_keyword AS mk ON a.id = mk.movie_id
    JOIN
        keyword AS k ON mk.keyword_id = k.id
    WHERE
        a.production_year >= 2000
),
TopKeywords AS (
    SELECT
        movie_id,
        STRING_AGG(movie_keyword, ', ') AS all_keywords
    FROM
        RankedMovies
    WHERE
        rank = 1
    GROUP BY
        movie_id
),
CastDetails AS (
    SELECT
        ci.movie_id,
        cn.name AS cast_member,
        rt.role AS role
    FROM
        cast_info AS ci
    JOIN
        char_name AS cn ON ci.person_id = cn.imdb_id
    JOIN
        role_type AS rt ON ci.role_id = rt.id
)
SELECT
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tk.all_keywords,
    STRING_AGG(cd.cast_member || ' as ' || cd.role, ', ') AS cast_list
FROM
    TopKeywords AS tk
JOIN
    aka_title AS tm ON tk.movie_id = tm.id
LEFT JOIN
    CastDetails AS cd ON tm.id = cd.movie_id
GROUP BY
    tm.movie_id, tm.movie_title, tm.production_year, tk.all_keywords
ORDER BY
    tm.production_year DESC;
