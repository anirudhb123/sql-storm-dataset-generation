WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT a.name) AS actors,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        actor_count,
        actors,
        keywords
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000 
        AND actor_count > 5
)
SELECT 
    movie_id,
    title,
    production_year,
    actor_count,
    STRING_AGG(DISTINCT actors::text, ', ') AS actor_list,
    STRING_AGG(DISTINCT keywords::text, ', ') AS keyword_list
FROM 
    FilteredMovies
GROUP BY 
    movie_id, title, production_year, actor_count
ORDER BY 
    production_year DESC, actor_count DESC;

This SQL query achieves the following:

1. **RankedMovies CTE**: First, it ranks movies by counting the number of unique actors associated with each movie, aggregates the actor names, and gathers keywords, grouped by movie attributes.

2. **FilteredMovies CTE**: Next, it filters these ranked movies to include only those that were produced after the year 2000 and have more than 5 distinct actors.

3. **Final Selection**: Finally, it selects the relevant information from the filtered subset, creating aggregated lists of actors and keywords for each movie, and orders the results by the production year and the number of actors.
