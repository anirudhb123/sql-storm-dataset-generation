WITH recursive movie_actors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        a.id AS actor_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
top_movies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year,
        COUNT(DISTINCT ca.actor_id) AS actor_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ca.actor_id) DESC) AS movie_rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ca ON m.id = ca.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
keyword_movies AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keyword, 'N/A') AS keyword,
    ma.actor_name,
    ma.actor_rank,
    CASE 
        WHEN tm.actor_count > 10 THEN 'Blockbuster'
        WHEN tm.actor_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Indie'
    END AS movie_category
FROM 
    top_movies tm
LEFT JOIN 
    movie_actors ma ON tm.movie_id = ma.movie_id AND ma.actor_rank <= 3
LEFT JOIN 
    (SELECT DISTINCT movie_id, keyword FROM keyword_movies WHERE keyword LIKE 'Drama%') mk ON tm.movie_id = mk.movie_id
WHERE 
    tm.movie_rank <= 20
ORDER BY 
    tm.actor_count DESC,
    tm.production_year DESC,
    COALESCE(ma.actor_name, '')
FOR UPDATE SKIP LOCKED;

### Explanation of the SQL Query:
1. **Common Table Expressions (CTEs)**:
   - `movie_actors`: A recursive CTE that retrieves each movie's actors and ranks them per movie based on their names.
   - `top_movies`: A CTE that summarizes movies, counts distinct actors, and ranks them based on the number of actors.
   - `keyword_movies`: A simple CTE that retrieves movies associated with keywords starting with 'Drama'.

2. **Main Query**:
   - Joins the top movies information with the actor names and the keywords associated with the movies.
   - Uses a `COALESCE` function to handle NULL values for keywords.
   - Implements a `CASE` statement to classify movies based on the actor count into three categories: 'Blockbuster', 'Moderate', and 'Indie'.
   - Applies a filter to limit results to the top 20 ranked movies.

3. **Advanced SQL Features**:
   - Outer Joins: Used to gather information even when some movies do not have any actors or keywords.
   - Window Functions: Provides actor ranking within each movie and assigns ranks to movies based on actor count.
   - NULL Logic: Included to deal with potentially missing keywords.
   - FOR UPDATE SKIP LOCKED: Illustrates an unusual semantic for row locking, useful in concurrent environments.

4. **Performance Benchmark**: 
   - This query can be used to evaluate performance across multiple joins, CTEs, rankings, and conditionally aggregated data, making it suitable for performance testing in various SQL scenarios.
