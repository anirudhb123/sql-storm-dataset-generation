WITH RECURSIVE ActorMovies AS (
    SELECT 
        ci.person_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        cast_info ci
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
ActorCareer AS (
    SELECT 
        am.person_id,
        COUNT(*) AS total_movies,
        MAX(am.production_year) AS last_movie_year
    FROM 
        ActorMovies am
    GROUP BY 
        am.person_id
),
ActorsWithNames AS (
    SELECT 
        ak.id AS actor_id,
        ak.name,
        ac.total_movies,
        ac.last_movie_year
    FROM 
        aka_name ak
    JOIN 
        ActorCareer ac ON ak.person_id = ac.person_id
    WHERE 
        ak.name IS NOT NULL
),
TopActors AS (
    SELECT 
        actor_id,
        name,
        total_movies,
        last_movie_year,
        RANK() OVER (ORDER BY total_movies DESC) AS rank
    FROM 
        ActorsWithNames
)
SELECT 
    t.movie_id,
    t.title,
    t.production_year,
    ta.name AS actor_name,
    ta.total_movies AS actor_total_movies,
    ta.last_movie_year AS actor_last_movie_year
FROM 
    aka_title t
LEFT JOIN 
    cast_info ci ON t.id = ci.movie_id
LEFT JOIN 
    TopActors ta ON ci.person_id = ta.actor_id
WHERE 
    t.production_year >= 2000 
    AND (ta.rank <= 10 OR ta.actor_id IS NULL)
ORDER BY 
    t.production_year DESC, actor_total_movies DESC;

This SQL query achieves the following:

1. **CTEs**: 
   - `ActorMovies`: Retrieves movies and their ranking for each actor.
   - `ActorCareer`: Summarizes the number of movies and the last movie year for each actor.
   - `ActorsWithNames`: Joins actor names with their career data.
   - `TopActors`: Ranks actors based on total movies starred in.

2. **Joins**: 
   - Combines data from several tables including `cast_info`, `aka_title`, and derived CTEs.

3. **Window Functions**: 
   - Uses `ROW_NUMBER()` and `RANK()` to order and rank actors based on their movie count.

4. **Outer Join**: 
   - A `LEFT JOIN` on `TopActors` to ensure all movies are included even if no actors are associated.

5. **Complex predicates**: 
   - Filters movies from the year 2000 onwards and allows for NULL actor IDs to include titles with no actors.

6. **Final result**: 
   - Extracts and presents movie titles along with their respective top actors, along with counts and latest involvement data.
