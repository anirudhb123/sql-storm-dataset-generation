
WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM
        aka_title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
CollaboratedActors AS (
    SELECT
        a.name,
        COUNT(DISTINCT m.title) AS collaborated_movies
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        aka_title m ON c.movie_id = m.id
    WHERE
        a.name IS NOT NULL
    GROUP BY
        a.id, a.name
    HAVING
        COUNT(DISTINCT m.id) > 1
),
MovieKeywords AS (
    SELECT
        t.title,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        t.id, t.title
)

SELECT
    rm.title,
    rm.production_year,
    COALESCE(ca.collaborated_movies, 0) AS collaborated_actors,
    mk.keywords
FROM
    RankedMovies rm
LEFT JOIN
    CollaboratedActors ca ON rm.title = ca.name
LEFT JOIN
    MovieKeywords mk ON rm.title = mk.title
WHERE
    rm.year_rank <= 5
ORDER BY
    rm.production_year DESC, rm.total_cast DESC;
