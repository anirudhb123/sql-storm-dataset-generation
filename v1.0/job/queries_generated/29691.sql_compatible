
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM
        aka_title AS t
    JOIN
        cast_info AS ci ON t.id = ci.movie_id
    JOIN
        aka_name AS a ON ci.person_id = a.person_id
    WHERE
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY
        t.id, t.title, t.production_year
),
MovieGenres AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT kg.keyword, ', ') AS keywords
    FROM
        movie_keyword AS mk
    JOIN
        keyword AS kg ON mk.keyword_id = kg.id
    JOIN
        aka_title AS t ON mk.movie_id = t.id
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('Action', 'Drama', 'Comedy'))
    GROUP BY
        mk.movie_id
),
PersonInfo AS (
    SELECT
        p.id AS person_id,
        p.name,
        STRING_AGG(DISTINCT pi.info, ', ') AS info_details
    FROM
        name p
    JOIN
        person_info pi ON p.id = pi.person_id
    GROUP BY
        p.id, p.name
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.cast_names,
    mg.keywords,
    pi.name AS lead_actor,
    pi.info_details
FROM
    RankedMovies rm
LEFT JOIN
    MovieGenres mg ON rm.movie_id = mg.movie_id
LEFT JOIN
    cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN
    PersonInfo pi ON ci.person_id = pi.person_id
WHERE
    rm.total_cast > 5
ORDER BY
    rm.production_year DESC, rm.total_cast DESC;
