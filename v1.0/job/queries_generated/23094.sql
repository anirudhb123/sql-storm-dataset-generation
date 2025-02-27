WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_summary AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_actors,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
keyword_info AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cs.num_actors,
    cs.actor_names,
    ki.keywords,
    CASE
        WHEN rm.year_rank < 5 THEN 'Top 5 of the Year'
        ELSE 'Not Top 5'
    END AS popularity_class
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_summary cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    keyword_info ki ON rm.movie_id = ki.movie_id
WHERE 
    (rm.production_year BETWEEN 2000 AND 2023)
    AND (cs.num_actors IS NOT NULL OR ki.keywords IS NOT NULL)
ORDER BY 
    rm.year_rank, cs.num_actors DESC NULLS LAST, rm.title
FETCH FIRST 50 ROWS ONLY;

### Explanation:
1. **Common Table Expressions (CTEs):**
   - `ranked_movies`: This CTE generates a ranked list of movies within each production year.
   - `cast_summary`: This CTE calculates the number of unique actors and aggregates their names for each movie.
   - `keyword_info`: This CTE aggregates keywords associated with each movie.

2. **Joins:**
   - The main query joins the `ranked_movies` with the `cast_summary` and `keyword_info` on the `movie_id`.

3. **Window Function:**
   - The `ROW_NUMBER()` window function is used to process ranking within movie production years.

4. **String Aggregation:**
   - The `STRING_AGG` function is used to concatenate actor names and keywords into single string fields.

5. **Conditional Logic:**
   - A new field, `popularity_class`, distinguishes whether a movie is in the top 5 of its production year.

6. **Complicated Predicate:**
   - The WHERE clause ensures the inclusion of movies produced between 2000 and 2023 and retains records only where there are actors or keyword information present.

7. **Ordering:**
   - The result is ordered by the ranking, number of actors (while placing NULLs last), and title.

8. **Limiting Results:**
   - The query limits output to the first 50 rows for performance benchmarking.
