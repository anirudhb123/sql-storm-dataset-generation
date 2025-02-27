WITH ActorTitles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS title_rank
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title t ON ci.movie_id = t.movie_id
    WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopMovies AS (
    SELECT 
        actor_id,
        actor_name,
        movie_title,
        production_year
    FROM ActorTitles
    WHERE title_rank <= 5
),

CoActors AS (
    SELECT 
        a1.actor_id AS actor_id,
        a1.actor_name AS primary_actor,
        a2.actor_name AS co_actor_name,
        COUNT(DISTINCT ci1.movie_id) AS co_movie_count
    FROM ActorTitles a1
    JOIN cast_info ci1 ON a1.actor_id = ci1.person_id
    JOIN cast_info ci2 ON ci1.movie_id = ci2.movie_id AND ci1.person_id <> ci2.person_id
    JOIN aka_name a2 ON ci2.person_id = a2.person_id
    WHERE a1.title_rank = 1  -- Only primary movies as per ranking
    GROUP BY a1.actor_id, a1.actor_name, a2.actor_name
),

MovieDetails AS (
    SELECT 
        mt.movie_id,
        m.title,
        COALESCE(mi.info, 'No Info Available') AS info,
        mt.note AS company_note,
        mk.keyword AS keywords
    FROM movie_companies mt
    LEFT JOIN title m ON mt.movie_id = m.id
    LEFT JOIN movie_info mi ON mi.movie_id = mt.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Plot')
    LEFT JOIN movie_keyword mk ON mk.movie_id = mt.movie_id
)

SELECT 
    ta.actor_name,
    ta.movie_title,
    ta.production_year,
    co.co_actor_name,
    co.co_movie_count,
    md.info,
    STRING_AGG(DISTINCT md.keywords, ', ') AS keywords
FROM TopMovies ta
LEFT JOIN CoActors co ON ta.actor_id = co.actor_id
LEFT JOIN MovieDetails md ON ta.movie_title = md.title
WHERE 
    co.co_movie_count > 3 OR
    md.info IS NOT NULL
GROUP BY 
    ta.actor_name, ta.movie_title, ta.production_year, co.co_actor_name, co.co_movie_count, md.info
HAVING 
    ARRAY_LENGTH(STRING_TO_ARRAY(md.info, ' '), 1) > 10   -- Filter out movies with small descriptions
ORDER BY 
    ta.production_year DESC, co.co_movie_count DESC;

### Query Explanation:
1. **CTEs (Common Table Expressions)**:
    - `ActorTitles`: Retrieves titles and production years for each actor and ranks them by production year.
    - `TopMovies`: Filters top 5 movies per actor based on the produced year.
    - `CoActors`: Finds co-actors for each primary actor and counts the distinct movies shared to establish co-actor relations.
    - `MovieDetails`: Collects movie metadata including additional information and keywords.

2. **Aggregations**:
    - Use of `STRING_AGG` to combine keywords associated with movies.

3. **LEFT JOINs**: Highlights relationships between tables where some data may not be fully matched, promoting NULL values and their handling.

4. **Complex Predicates**: Filters results based on the number of co-movie counts and ensures that info columns that indicate significant movie details are substantially populated.

5. **Corner Cases**:
    - The `HAVING` clause uses an array length filter to validate significant plot information is available due to possible edge scenarios in the plot descriptions. 

6. **Ordered Result**: The result is ordered by production year and the count of co-acting movies. 

### Bizarre SQL Semantics:
- Utilizes both `COALESCE` for NULL handling and array functions to manipulate text data for dynamic data collection. 

This query benchmarks multiple aspects of SQL performance, integrating various complexities and SQL features into a singular cohesive structure.
