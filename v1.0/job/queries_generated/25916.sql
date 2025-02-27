WITH ActorMovieCount AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name
),
MovieKeywordCounts AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id, m.title
),
HighProfileActors AS (
    SELECT 
        am.actor_id,
        am.actor_name
    FROM 
        ActorMovieCount am
    WHERE 
        am.movie_count > 10
),
TopMovies AS (
    SELECT 
        mk.movie_id,
        mk.movie_title,
        RANK() OVER (ORDER BY mk.keyword_count DESC) AS rank
    FROM 
        MovieKeywordCounts mk
    WHERE 
        mk.keyword_count > 5
)
SELECT 
    h.actor_name,
    t.movie_title,
    t.rank
FROM 
    HighProfileActors h
JOIN 
    cast_info c ON h.actor_id = c.person_id
JOIN 
    TopMovies t ON c.movie_id = t.movie_id
ORDER BY 
    h.actor_name, t.rank;

This query performs the following operations:
1. Calculates the number of movies for each actor in the `aka_name` table by joining with the `cast_info` table.
2. Determines the number of keywords associated with each movie in the `aka_title` table.
3. Identifies actors with more than 10 movies in the `HighProfileActors` common table expression (CTE).
4. Identifies movies with more than 5 keywords in the `TopMovies` CTE and ranks them.
5. Finally, it selects actor names from `HighProfileActors` and their corresponding top movies from `TopMovies`, ordered by actor name and rank.
