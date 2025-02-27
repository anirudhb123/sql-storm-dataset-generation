WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    LEFT JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.actors
    FROM
        RankedMovies rm
    WHERE
        rm.rank <= 5
)

SELECT
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.total_cast,
    fm.actors,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT ci.kind, ', ') AS company_types
FROM
    FilteredMovies fm
LEFT JOIN
    movie_keyword mk ON fm.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_companies mc ON fm.movie_id = mc.movie_id
LEFT JOIN
    company_type ci ON mc.company_type_id = ci.id
GROUP BY
    fm.movie_id, fm.title, fm.production_year, fm.total_cast, fm.actors
ORDER BY
    fm.production_year DESC, fm.total_cast DESC;
