WITH ActorMovies AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ct.kind AS company_type,
        k.keyword AS movie_keyword
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        aka_title t ON c.movie_id = t.id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        a.name IS NOT NULL
        AND t.production_year >= 2000
        AND ct.kind IS NOT NULL
),
AggregatedInfo AS (
    SELECT
        actor_name,
        COUNT(movie_title) AS total_movies,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM
        ActorMovies
    GROUP BY
        actor_name
)
SELECT
    actor_name,
    total_movies,
    keywords
FROM
    AggregatedInfo
ORDER BY
    total_movies DESC
LIMIT 10;
