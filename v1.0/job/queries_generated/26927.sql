WITH ActorMovies AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        aka_title t ON ci.movie_id = t.movie_id
),
MovieKeywords AS (
    SELECT
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword m
    JOIN
        keyword k ON m.keyword_id = k.id
    GROUP BY
        m.movie_id
),
ActorDetails AS (
    SELECT
        am.actor_id,
        am.actor_name,
        am.movie_title,
        am.production_year,
        mk.keywords
    FROM
        ActorMovies am
    LEFT JOIN
        MovieKeywords mk ON am.movie_title = mk.movie_id
)
SELECT 
    ad.actor_name,
    COUNT(DISTINCT ad.movie_title) AS total_movies,
    STRING_AGG(DISTINCT ad.keywords, '; ') AS all_keywords,
    AVG(ad.production_year) AS average_production_year
FROM
    ActorDetails ad
GROUP BY
    ad.actor_name
HAVING
    COUNT(DISTINCT ad.movie_title) > 5
ORDER BY
    total_movies DESC 
LIMIT 10;
