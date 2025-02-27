WITH ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year AS release_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS ci ON a.person_id = ci.person_id
    JOIN 
        aka_title AS t ON ci.movie_id = t.movie_id
    JOIN 
        movie_keyword AS mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        a.id, a.name, t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        actor_id,
        actor_name,
        movie_title,
        release_year,
        keywords,
        RANK() OVER (PARTITION BY actor_id ORDER BY release_year DESC) AS rank
    FROM 
        ActorMovies
)

SELECT 
    am.actor_name,
    string_agg(DISTINCT am.movie_title, ', ') AS movies,
    string_agg(DISTINCT array_to_string(am.keywords, ', '), ', ') AS associated_keywords,
    COUNT(*) AS total_movies
FROM 
    TopMovies AS am
WHERE 
    rank <= 5 -- Fetching the top 5 recent movies for each actor
GROUP BY 
    am.actor_id, am.actor_name
ORDER BY 
    total_movies DESC;
