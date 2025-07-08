
WITH MovieRankings AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        ARRAY_AGG(DISTINCT a.name) AS actors,
        COUNT(DISTINCT c.person_role_id) AS actor_count,
        t.production_year,
        k.keyword AS genre,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(DISTINCT c.person_role_id) DESC) AS ranking
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        movie_keyword mw ON t.id = mw.movie_id
    JOIN 
        keyword k ON mw.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        actors,
        actor_count,
        production_year,
        genre
    FROM 
        MovieRankings
    WHERE 
        ranking = 1
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    LISTAGG(DISTINCT tm.actors::text, ', ') AS all_actors,
    LISTAGG(DISTINCT tm.genre, ', ') AS all_genres
FROM 
    TopMovies tm
GROUP BY 
    tm.title, tm.production_year, tm.actor_count
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
