WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS movie_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CoActors AS (
    SELECT 
        c1.person_id AS person_id,
        c1.movie_id AS movie_id,
        c2.person_id AS co_actor_id,
        COUNT(DISTINCT c2.person_id) AS co_actor_count
    FROM 
        cast_info c1
    JOIN 
        cast_info c2 ON c1.movie_id = c2.movie_id AND c1.person_id <> c2.person_id
    GROUP BY 
        c1.person_id, c1.movie_id
),
ActorMovies AS (
    SELECT 
        a.id AS person_id,
        a.name AS actor_name,
        r.movie_id,
        r.title,
        r.production_year,
        COALESCE(c.co_actor_count, 0) AS co_actor_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        RankedMovies r ON ci.movie_id = r.movie_id
    LEFT JOIN 
        CoActors c ON c.person_id = a.person_id AND c.movie_id = r.movie_id
),
FilteredTitles AS (
    SELECT 
        am.actor_name,
        am.movie_id,
        am.title,
        am.production_year,
        am.co_actor_count
    FROM 
        ActorMovies am
    WHERE 
        am.production_year BETWEEN 1995 AND 2005
        AND am.co_actor_count >= 2
)
SELECT 
    ft.actor_name,
    ARRAY_AGG(DISTINCT ft.title) AS titles,
    COUNT(DISTINCT ft.movie_id) AS total_movies,
    MIN(ft.production_year) AS first_movie,
    MAX(ft.production_year) AS last_movie,
    BOOL_OR(ft.co_actor_count > 3) AS has_high_coactors
FROM 
    FilteredTitles ft
GROUP BY 
    ft.actor_name
ORDER BY 
    total_movies DESC
LIMIT 10;

This SQL query performs the following tasks:

1. **Common Table Expressions (CTEs)**: 
   - `RankedMovies` creates a ranking of movies per production year while counting them.
   - `CoActors` identifies co-actors for each actor in each movie.
   - `ActorMovies` combines the actor information with movie details and their co-actor counts.
   - `FilteredTitles` filters out movies based on production year and co-actor criteria.

2. **Aggregates**: 
   - It aggregates the titles viewed by actors and counts total movies while capturing the earliest and latest production years.

3. **Conditional Logic**: 
   - It checks if an actor has collaborated with a high number of co-actors using the `BOOL_OR` function.

4. **String and Array Aggregation**: 
   - It uses `ARRAY_AGG` to create a list of movie titles for each actor.

5. **Obscure and Complicated Predicates**: 
   - The use of `COALESCE` manages potential NULL values in actor counts.

This query could provide interesting insights into actor collaborations during a specific decade.
