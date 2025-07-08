
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        r.role,
        COUNT(c.person_id) AS cast_count
    FROM
        aka_title t
    JOIN
        cast_info c ON t.id = c.movie_id
    LEFT JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        t.id, t.title, t.production_year, r.role
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        MAX(cast_count) OVER (PARTITION BY production_year) AS max_cast_count
    FROM
        RankedMovies
)
SELECT
    m.movie_id,
    m.title,
    m.production_year,
    m.max_cast_count,
    ak.name AS actor_name,
    ak.md5sum AS actor_md5sum,
    ct.kind AS company_type,
    LISTAGG(DISTINCT k.keyword, ', ') AS keywords
FROM
    TopMovies m
JOIN
    complete_cast cc ON m.movie_id = cc.movie_id
JOIN
    aka_name ak ON cc.subject_id = ak.person_id
JOIN
    movie_companies mc ON mc.movie_id = m.movie_id
JOIN
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
WHERE
    m.max_cast_count > 5
GROUP BY
    m.movie_id, m.title, m.production_year, m.max_cast_count, ak.name, ak.md5sum, ct.kind
ORDER BY
    m.production_year DESC, m.max_cast_count DESC;
