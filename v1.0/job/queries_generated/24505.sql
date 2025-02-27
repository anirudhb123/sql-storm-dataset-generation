WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT mk.keyword) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        STRING_AGG(DISTINCT at.title, ', ') AS movie_titles
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.id
),
TheatreActors AS (
    SELECT 
        ca.id AS actor_id,
        ca.name AS actor_name,
        COALESCE(ar.total_movies, 0) AS total_movies,
        COALESCE(ar.movie_titles, 'No movies') AS movie_titles
    FROM 
        char_name ca
    LEFT JOIN 
        ActorRoles ar ON ca.name = ar.actor_name
)
SELECT 
    ta.actor_id,
    ta.actor_name,
    ta.total_movies,
    ta.movie_titles,
    tm.title AS top_movie,
    tm.production_year
FROM 
    TheatreActors ta
LEFT JOIN 
    TopMovies tm ON ta.total_movies > 0 
WHERE 
    ta.actor_name IS NOT NULL AND 
    (tm.production_year IS NULL OR tm.production_year > 2000)
ORDER BY 
    ta.total_movies DESC, 
    COALESCE(tm.production_year, 9999) ASC;

This query does the following:
1. **With Clauses (CTEs)**: 
   - `RankedMovies` ranks movies based on the number of unique keywords associated with them, partitioned by the production year.
   - `TopMovies` filters the ranked movies to select the top 5 movies per production year.
   - `ActorRoles` aggregates actor data and their movie roles, capturing their total movies and a concatenated string of movie titles.
   - `TheatreActors` makes sure to include all actors, whether they have roles or not, using a left join with `ActorRoles`.

2. **Main Selection**: 
   - Combines actor data with top movies for actors who have appeared in movies after 2000 and presents the total count of movies and titles.

3. **Nullable Logic**: 
   - It utilizes `COALESCE` to handle potential null values, providing default values for absent movies.

4. **Complex Conditions**: 
   - It leverages multiple join types, window functions, and aggregate functions to create a comprehensive view of actors and their association with top movies, reflecting the complex relationships between various entities in the schema.

5. **Order and Filtering**: 
   - Finally, sorting actors based on their movie count in descending order followed by movie year in ascending order (defaulting to a far future year for null production years).
