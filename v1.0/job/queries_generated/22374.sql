WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
AggregatedActors AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT n.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        name n ON a.person_id = n.imdb_id
    GROUP BY 
        a.person_id
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        a.actor_names,
        a.movie_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        AggregatedActors a ON rm.year_rank = 1 AND a.movie_count > 5
    WHERE 
        rm.production_year > 2000
)
SELECT 
    fm.production_year, 
    fm.title, 
    COALESCE(fm.actor_names, 'No Actor') AS actor_names, 
    COUNT(DISTINCT ci.movie_id) OVER (PARTITION BY fm.production_year) AS total_movies
FROM 
    FilteredMovies fm
LEFT OUTER JOIN 
    cast_info ci ON fm.title = (SELECT title FROM aka_title WHERE movie_id = ci.movie_id)
WHERE 
    fm.production_year IS NOT NULL
ORDER BY 
    fm.production_year DESC, 
    fm.title;

### Explanation:

1. **CTEs:** 
   - The first Common Table Expression `RankedMovies` ranks movies by their production year, grouping by the year while also capturing associated keywords.
   - The second CTE `AggregatedActors` counts the number of distinct movies each actor has been in and aggregates their names into a string for easy display.
   - The third CTE `FilteredMovies` combines the results of the first two, focusing on movies produced after 2000 and ensuring only actors with more than 5 movies are considered.

2. **Outer Joins:** 
   - The final selection employs a left outer join on `cast_info` to attempt to match movies back to the cast, even when there might be no matches.

3. **Window Functions:** 
   - The `ROW_NUMBER()` function is used to partition and rank the movies within each production year.

4. **String Aggregation:** 
   - `STRING_AGG` helps in concatenating the names of actors into a single field.

5. **Complicated Conditions:** 
   - Predicates guarantee that only relevant records from the joined tables are considered, e.g., enforcing that only actors with a minimum movie count are included.

6. **NULL Logic:** 
   - The use of `COALESCE` ensures that if no actor matches, a default result is returned, showing that no actor is associated with a particular movie.

7. **Ordering:** 
   - The final results are ordered by production year in descending order, followed by title, which ensures a clear and logical output format.

This SQL query combines various elements and constructs to fulfill performance benchmarking requirements while also demonstrating some less common SQL functionalities.
