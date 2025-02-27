WITH RankedMovies AS (
    SELECT
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS rn
    FROM
        aka_title m
    LEFT JOIN
        cast_info c ON m.id = c.movie_id
    LEFT JOIN
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.id
),
FilteredMovies AS (
    SELECT
        rm.movie_title,
        rm.production_year,
        rm.actors,
        rm.keywords,
        COUNT(CASE WHEN mk.keyword LIKE '%action%' THEN 1 END) AS action_keyword_count
    FROM
        RankedMovies rm
    WHERE
        rm.rn = 1
    GROUP BY
        rm.movie_title, rm.production_year, rm.actors, rm.keywords
)
SELECT
    f.movie_title,
    f.production_year,
    f.actors,
    f.keywords,
    f.action_keyword_count
FROM
    FilteredMovies f
WHERE
    f.production_year > 2000
ORDER BY
    f.production_year DESC,
    f.action_keyword_count DESC;
