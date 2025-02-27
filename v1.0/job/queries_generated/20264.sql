WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(pi.rating) AS avg_rating
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        (SELECT 
            movie_id, 
            AVG(info::numeric) AS rating
         FROM 
            movie_info 
         WHERE 
            info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')
         GROUP BY 
            movie_id) pi ON mt.id = pi.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.title, mt.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
TopRatedMovies AS (
    SELECT 
        RANK() OVER (ORDER BY avg_rating DESC) AS rank,
        title,
        production_year,
        actor_count
    FROM 
        RankedMovies
),
FrequentGenres AS (
    SELECT 
        mt.id AS movie_id,
        array_agg(DISTINCT kt.keyword) AS genres
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        mt.id
    HAVING 
        COUNT(DISTINCT kt.keyword) > 2
)
SELECT 
    T.rank,
    T.title,
    T.production_year,
    T.actor_count,
    COALESCE(F.genres, '{}') AS genres
FROM 
    TopRatedMovies T
LEFT JOIN 
    FrequentGenres F ON T.title = F.movie_id
WHERE 
    T.rank <= 10
ORDER BY 
    T.avg_rating DESC, T.production_year ASC;

Here is a breakdown of the SQL query:

1. **CTEs (Common Table Expressions)**:
   - `RankedMovies`: This CTE selects movie titles and their production years, counting the distinct number of actors in each movie. It calculates the average rating of the movies by correlating them with movie info and filtering for those with more than 5 actors.
   - `TopRatedMovies`: Ranks the movies from the `RankedMovies` CTE by their average rating.
   - `FrequentGenres`: Gathers genres (keywords) associated with movies that have more than two distinct genres, using an array aggregation for easier presentation.

2. **Outer Join**: The CTE `FrequentGenres` is left joined with the `TopRatedMovies` to include genre information, even if it's absent.

3. **COALESCE**: Used to handle cases where genres might be NULL, replacing them with an empty array `('{}')`.

4. **HAVING Clauses**: Applied to filter results within the CTEs to ensure specific business logic (more than 5 actors and more than 2 genres).

5. **Window Functions**: Used to rank the movies based on average ratings.

6. **Complex Predicate Logic**: Filtering on the number of actors and the presence of genres ensures that only movies meeting those criteria are selected.

7. **Ordering**: The final output is ordered by average rating in descending order and then by production year in ascending order, creating an interesting way to view top movies.

This query demonstrates multiple SQL techniques and complex logic in a unified structure, ideal for performance benchmarking challenges.
