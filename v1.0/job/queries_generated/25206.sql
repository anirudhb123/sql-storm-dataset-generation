WITH NameMovieInfo AS (
    SELECT 
        a.name AS actor_name,
        a.id AS actor_id,
        t.title AS movie_title,
        t.production_year,
        mk.keyword AS movie_keyword,
        c.kind AS cast_type
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN comp_cast_type c ON ci.role_id = c.id
    WHERE a.name IS NOT NULL
),
AggregatedInfo AS (
    SELECT
        Nm.actor_name,
        COUNT(DISTINCT Nm.movie_title) AS movie_count,
        STRING_AGG(DISTINCT Nm.movie_keyword, ', ') AS keywords,
        MAX(Nm.production_year) AS last_movie_year
    FROM NameMovieInfo Nm
    GROUP BY Nm.actor_name
)
SELECT 
    a.actor_name,
    a.movie_count,
    a.keywords,
    a.last_movie_year,
    COALESCE(d.role_count, 0) AS role_count
FROM AggregatedInfo a
LEFT JOIN (
    SELECT 
        actor_name,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    GROUP BY actor_name
) d ON a.actor_name = d.actor_name
ORDER BY a.movie_count DESC, a.last_movie_year DESC;

This SQL query compiles intriguing data regarding actors, including their names, the number of movies they participated in, the corresponding keywords associated with those movies, and the last production year of their films. This information can be useful for benchmarking string processing by evaluating how different string representations affect join operations and aggregations within complex queries.
