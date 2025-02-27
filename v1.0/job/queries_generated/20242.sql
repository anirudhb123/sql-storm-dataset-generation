WITH RecursiveActorHierarchy AS (
    SELECT
        c.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        RANK() OVER (PARTITION BY c.person_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rank
    FROM
        cast_info c
    JOIN
        aka_name a ON a.person_id = c.person_id
    GROUP BY
        c.person_id, a.name
),
TopActors AS (
    SELECT
        ra.actor_name,
        ra.movie_count
    FROM
        RecursiveActorHierarchy ra
    WHERE
        ra.rank <= 10
),
MovieInfo AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(mk.keyword SEPARATOR ', ') AS keywords,
        REGEXP_REPLACE(m.title, '[^a-zA-Z0-9]', '') AS sanitized_title
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY
        m.id, m.title, m.production_year
)
SELECT
    ta.actor_name,
    mi.title,
    mi.production_year,
    mi.keywords,
    COUNT(DISTINCT c.movie_id) OVER (PARTITION BY ta.actor_name) AS total_movies,
    CASE
        WHEN mi.production_year IS NULL THEN 'Unknown Year'
        ELSE CAST(mi.production_year AS VARCHAR)
    END AS production_year_display,
    COALESCE(NULLIF(ta.movie_count, 0), 'No Movies') AS movie_count_display
FROM
    TopActors ta
CROSS JOIN
    MovieInfo mi
LEFT JOIN
    cast_info c ON c.movie_id = mi.movie_id AND c.person_id = (SELECT MIN(c2.person_id) FROM cast_info c2 WHERE c2.movie_id = mi.movie_id)
WHERE
    mi.keywords LIKE '%drama%'
    OR EXISTS (
        SELECT 1
        FROM movie_info mi2
        WHERE mi2.movie_id = mi.movie_id AND mi2.info LIKE '%blockbuster%'
    )
ORDER BY
    ta.movie_count DESC,
    mi.production_year DESC;
