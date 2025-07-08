
WITH RecursiveActorMovies AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM
        aka_name AS a
    JOIN
        cast_info AS ci ON a.person_id = ci.person_id
    JOIN
        aka_title AS t ON ci.movie_id = t.movie_id
    WHERE
        a.name IS NOT NULL AND a.name <> ''
        AND t.production_year >= 2000
),
TopActors AS (
    SELECT 
        actor_id,
        actor_name,
        movie_id,
        movie_title,
        production_year
    FROM
        RecursiveActorMovies
    WHERE
        movie_rank <= 3
),
ActorPatterns AS (
    SELECT
        actor_id,
        actor_name,
        COUNT(*) AS movies_count,
        LISTAGG(movie_title, ', ') WITHIN GROUP (ORDER BY movie_title) AS movie_titles
    FROM
        TopActors
    GROUP BY
        actor_id, actor_name
    HAVING
        COUNT(*) > 1
),
UnseenMovies AS (
    SELECT 
        DISTINCT t.id AS movie_id,
        t.title AS title,
        k.keyword AS genre_keyword
    FROM
        aka_title AS t
    LEFT JOIN
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        t.id NOT IN (SELECT movie_id FROM cast_info)
        AND t.production_year >= 2015
        AND k.keyword IS NULL
),
FinalComparison AS (
    SELECT
        ap.actor_name,
        ap.movies_count,
        COALESCE(SUM(CASE WHEN um.genre_keyword IS NULL THEN 0 ELSE 1 END), 0) AS unique_genre_count,
        ARRAY_AGG(um.title) AS unseen_movies
    FROM
        ActorPatterns AS ap
    LEFT JOIN
        UnseenMovies AS um ON ap.actor_id = um.movie_id
    GROUP BY
        ap.actor_name, ap.movies_count
)
SELECT
    actor_name,
    movies_count,
    unique_genre_count,
    unseen_movies,
    CASE 
        WHEN movies_count > 5 THEN 'Prolific Actor'
        WHEN movies_count BETWEEN 3 AND 5 THEN 'Moderate Actor'
        ELSE 'Newcomer' 
    END AS actor_type
FROM
    FinalComparison
WHERE
    unique_genre_count >= 1 OR unseen_movies IS NOT NULL
ORDER BY
    movies_count DESC, actor_name;
