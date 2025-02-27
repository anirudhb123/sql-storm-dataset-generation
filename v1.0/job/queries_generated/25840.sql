WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        aka_name.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY title.id ORDER BY title.production_year DESC) AS rank
    FROM 
        title
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        company_name.country_code = 'USA'
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    STRING_AGG(rm.actor_name, ', ') AS actors
FROM 
    RankedMovies rm
WHERE 
    rm.rank = 1
GROUP BY 
    rm.movie_id, rm.title, rm.production_year
ORDER BY 
    rm.production_year DESC;

### Explanation of the Query:
1. **Common Table Expression (CTE)**: The query uses a CTE to rank movies by their production year while gathering relevant actor information from various joined tables.
  
2. **Joins**: It performs several joins across the `title`, `movie_companies`, `company_name`, `cast_info`, and `aka_name` tables. This retrieves the movies produced by companies located in the USA and their associated actors.

3. **Ranking**: The `ROW_NUMBER()` function is used to rank movies based on the production year in descending order. This helps select only the latest production for each movie.

4. **Aggregation**: The `STRING_AGG` function groups the names of actors for each movie, ensuring that all relevant actor names are concatenated into a single string.

5. **Final Selection**: The outer query fetches the movies and their relevant actors filtered by rank to get only the latest entries, and orders the result by production year.
