WITH ranked_movies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank_by_year,
        COUNT(*) OVER (PARTITION BY at.production_year) AS total_movies_per_year
    FROM 
        aka_title at
),
top_movies AS (
    SELECT 
        rm.*
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank_by_year <= 5
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors_list
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
final_result AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        cd.total_actors,
        CASE 
            WHEN cd.total_actors IS NULL THEN 'No Actors' 
            ELSE cd.total_actors::text 
        END AS actor_count,
        COALESCE(cd.actors_list, 'No actors listed') AS actors
    FROM 
        top_movies tm
    LEFT JOIN 
        cast_details cd ON tm.movie_id = cd.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    fr.actor_count,
    fr.actors
FROM 
    final_result fr
WHERE 
    fr.production_year > 2000
ORDER BY 
    fr.production_year DESC,
    fr.title ASC
LIMIT 10
OFFSET 5;

This SQL query performs the following tasks:

1. **Common Table Expressions (CTEs)**: 
   - `ranked_movies` CTE ranks movies by title within each production year and counts total movies for each year.
   - `top_movies` selects the top 5 movies from each production year based on the previously calculated rank.
   - `cast_details` aggregates cast information for these top movies, counting distinct actors and creating a list of their names.

2. **Final Result Computation**:
   - `final_result` combines information from `top_movies` and `cast_details`, applying conditional logic to handle NULL values, ensuring readability of counts and lists.

3. **Filtering and Pagination**: 
   - The outer query filters movies produced after 2000 and orders them by production year and title while applying pagination to limit the results and skip the first 5 entries.

This creates a complex yet informative output showing the titles and production years of select movies alongside their actor counts and names, utilizing various SQL features including outer joins, CTEs, aggregations, string functions, and conditional logic.
