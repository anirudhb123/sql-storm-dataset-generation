
WITH RankedMovies AS (
    SELECT
        ak.id AS aka_id,
        ak.name AS aka_name,
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY m.production_year DESC) AS rn
    FROM
        aka_name ak
    JOIN
        cast_info c ON ak.person_id = c.person_id
    JOIN
        aka_title m ON c.movie_id = m.movie_id
    WHERE
        ak.name IS NOT NULL
),

TopRankedMovies AS (
    SELECT
        aka_id,
        aka_name,
        movie_id,
        movie_title,
        production_year
    FROM
        RankedMovies
    WHERE
        rn = 1
)

SELECT
    ak.name AS Actor_Name,
    tm.movie_title AS Latest_Movie,
    tm.production_year,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS Associated_Keywords,
    LISTAGG(DISTINCT ci.kind, ', ') WITHIN GROUP (ORDER BY ci.kind) AS Movie_Companies
FROM
    TopRankedMovies tm
JOIN
    aka_name ak ON tm.aka_id = ak.id
LEFT JOIN
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN
    company_type ci ON mc.company_type_id = ci.id
GROUP BY
    ak.name, tm.movie_title, tm.production_year
ORDER BY
    production_year DESC;
