WITH ActorTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        c.nm_order AS cast_order,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.name, t.title, t.production_year, t.kind_id, c.nr_order
),
ActorCount AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count
    FROM 
        ActorTitles
    GROUP BY 
        actor_name
),
TopActors AS (
    SELECT 
        actor_name,
        movie_count
    FROM 
        ActorCount
    WHERE 
        movie_count > 5  -- only consider actors with more than 5 movies
    ORDER BY 
        movie_count DESC
    LIMIT 10
)
SELECT 
    a.actor_name,
    a.movie_title,
    a.production_year,
    kt.kind AS movie_kind,
    a.keywords
FROM 
    ActorTitles a
JOIN 
    kind_type kt ON a.kind_id = kt.id
JOIN 
    TopActors ta ON a.actor_name = ta.actor_name
ORDER BY 
    a.actor_name, a.production_year DESC;

This SQL query does the following:

1. **ActorTitles CTE**: Generates a list of actors with their corresponding movie titles, the production year, the type of movie, their cast order in the film, and aggregating the associated keywords into a comma-separated string.

2. **ActorCount CTE**: Counts the number of distinct movies each actor has appeared in, filtering for those with more than five films.

3. **TopActors CTE**: Selects the top ten actors based on the movie count.

4. **Final Select**: Joins back to the original dataset to gather all relevant information for the top actors including film titles, years, types of films, and keywords. Finally, it orders the results alphabetically by actor name and by production year in descending order.
