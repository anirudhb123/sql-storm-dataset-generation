WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM 
        aka_title at
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        AND at.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        ki.person_id,
        am.title_id,
        COUNT(*) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name kn ON ci.person_id = kn.person_id
    JOIN 
        RankedMovies am ON ci.movie_id = am.title_id
    GROUP BY 
        ki.person_id, am.title_id
),
TopActors AS (
    SELECT 
        person_id,
        SUM(movie_count) AS total_movies
    FROM 
        ActorMovies
    GROUP BY 
        person_id
    HAVING 
        SUM(movie_count) > 5
)
SELECT 
    a.id AS actor_id,
    a.name,
    COUNT(DISTINCT am.title_id) AS num_movies,
    MAX(am.production_year) AS latest_movie_year,
    STRING_AGG(DISTINCT am.title, ', ') AS movie_titles,
    CASE 
        WHEN MAX(am.production_year) IS NULL THEN 'No Movies'
        ELSE 'Active Actor'
    END AS actor_status
FROM 
    aka_name a
LEFT JOIN 
    ActorMovies am ON a.person_id = am.person_id
LEFT JOIN 
    company_name cn ON EXISTS (SELECT 1 FROM movie_companies mc WHERE mc.movie_id = am.title_id AND mc.company_id = cn.id)
WHERE 
    a.name IS NOT NULL
    AND (a.name_pcode_cf IS NOT NULL OR a.name_pcode_nf IS NOT NULL)
GROUP BY 
    a.id, a.name
ORDER BY 
    num_movies DESC NULLS LAST, latest_movie_year DESC;

### Explanation of the Query:
1. **Common Table Expressions (CTEs)**:
   - **RankedMovies**: Ranks movies by production year allowing filtering of the latest releases.
   - **ActorMovies**: Joins the `cast_info` and `aka_name` tables to gather information about actors and their films, counting the number of movies each actor has appeared in.
   - **TopActors**: Filters actors who have appeared in more than 5 movies.

2. **Main Query**:
   - Joins `aka_name` with the ActorMovies CTE to aggregate the number of movies by each actor.
   - A `LEFT JOIN` with `company_name` checks if any movie they were in has a corresponding company (utilizing an `EXISTS` clause).
   - Conditional selection of an actor's status based on the latest movie year.

3. **Use of Window Functions**: The query ranks movies and counts distinct movie appearances per actor.

4. **Aggregation and Formatting**: 
   - The use of `STRING_AGG` allows for the concatenation of movie titles for each actor, providing a compact look at their contributions.

5. **Complicated Predicates and NULL Logic**: The `WHERE` clause contains checks for `NULL` and non-null conditions, providing resilience against missing data. 

6. **Bizarre SQL Semantics**: Incorporates the idea of an actor being counted even if they have no movies (with respect to `NULL` logic) and uses string aggregation to list movies dynamically. 

7. **Ordering**: Orders results by the number of movies, giving priority to active actors while handling `NULL` values accordingly.
