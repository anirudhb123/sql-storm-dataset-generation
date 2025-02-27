WITH RECURSIVE ActorHierarchy AS (
    SELECT
        c.person_id,
        a.name AS actor_name,
        1 AS level
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        a.name IS NOT NULL

    UNION ALL

    SELECT
        c.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        ActorHierarchy ah ON c.movie_id IN (
            SELECT
                movie_id
            FROM
                cast_info ci
            WHERE
                ci.person_id = ah.person_id
        )
    WHERE
        a.name IS NOT NULL
),
PopularMovies AS (
    SELECT
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        title m
    JOIN
        cast_info c ON m.id = c.movie_id
    GROUP BY
        m.id
    HAVING
        COUNT(DISTINCT c.person_id) > 5
),
MovieKeywords AS (
    SELECT
        mka.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mka
    JOIN
        keyword k ON mka.keyword_id = k.id
    GROUP BY
        mka.movie_id
),
MovieInfo AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        CASE
            WHEN m.production_year IS NULL THEN 'Year Unknown'
            ELSE m.production_year::text
        END AS production_year
    FROM
        title m
    LEFT JOIN
        MovieKeywords mk ON m.id = mk.movie_id
)
SELECT
    mh.actor_name,
    mi.title,
    mi.production_year,
    mi.keywords,
    ah.level
FROM
    ActorHierarchy ah
JOIN
    MovieInfo mi ON ah.person_id IN (
        SELECT
            c.person_id
        FROM
            cast_info c
        WHERE
            c.movie_id IN (
                SELECT
                    id
                FROM
                    PopularMovies
            )
    )
ORDER BY
    ah.level DESC, mi.production_year DESC;

This SQL query performs performance benchmarking by combining various complex elements such as recursive CTEs to build an actor hierarchy, a subquery to identify popular movies, and another CTE to retrieve associated keywords. The final part selects relevant data, enriching the information about actors and the movies in which they have participated, and orders the results by actor hierarchy level and production year.
