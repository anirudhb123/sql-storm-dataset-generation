
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        aka_title t
    JOIN
        cast_info c ON t.id = c.movie_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        t.id, t.title, t.production_year, t.kind_id
),
FilteredMovies AS (
    SELECT
        rm.*,
        RANK() OVER (PARTITION BY rm.kind_id ORDER BY rm.cast_count DESC) AS rank
    FROM
        RankedMovies rm
    WHERE
        rm.production_year >= 2000
)

SELECT
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    f.actors,
    f.keywords
FROM
    FilteredMovies f
WHERE
    f.rank <= 5
ORDER BY
    f.kind_id, f.cast_count DESC;
