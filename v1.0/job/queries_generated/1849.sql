WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id
),
PersonDetails AS (
    SELECT
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(pi.info::int) FILTER (WHERE pi.info_type_id = 1) AS average_rating
    FROM
        aka_name a
    INNER JOIN
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN
        person_info pi ON a.person_id = pi.person_id
    WHERE
        a.name IS NOT NULL
    GROUP BY
        a.person_id, a.name
),
RankedMovies AS (
    SELECT
        md.*,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.production_year DESC) AS year_rank
    FROM
        MovieDetails md
)
SELECT
    pd.name AS actor_name,
    rm.title AS movie_title,
    rm.production_year,
    ARRAY_TO_STRING(rm.keywords, ', ') AS movie_keywords,
    pd.movie_count,
    COALESCE(pd.average_rating, 0) AS actor_average_rating
FROM
    PersonDetails pd
INNER JOIN
    cast_info ci ON pd.person_id = ci.person_id
INNER JOIN
    RankedMovies rm ON ci.movie_id = rm.movie_id
WHERE
    rm.year_rank <= 5
ORDER BY
    rm.production_year DESC, pd.movie_count DESC;
