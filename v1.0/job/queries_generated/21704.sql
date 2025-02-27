WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id) AS rank_by_year
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
AkaNames AS (
    SELECT 
        ak.person_id,
        STRING_AGG(ak.name, ', ') AS all_names
    FROM 
        aka_name ak
    GROUP BY 
        ak.person_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(ac.actor_count, 0) AS total_actors,
    rk.rank_by_year,
    ak.all_names,
    mii.info AS additional_info
FROM 
    RankedMovies m
LEFT JOIN 
    ActorCounts ac ON m.movie_id = ac.movie_id
LEFT JOIN 
    AkaNames ak ON ak.person_id IN (
        SELECT 
            c.person_id 
        FROM 
            cast_info c
        WHERE 
            c.movie_id = m.movie_id
    )
LEFT JOIN 
    movie_info_idx mii ON m.movie_id = mii.movie_id AND mii.info_type_id = (SELECT id FROM info_type WHERE info = 'synopsis')
WHERE 
    m.production_year >= 2000
    AND m.production_year <= (SELECT MAX(production_year) FROM title) 
ORDER BY 
    m.production_year DESC, m.title
FETCH FIRST 10 ROWS ONLY;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - `RankedMovies`: Calculates a rank for each movie based on its production year.
   - `ActorCounts`: Counts the number of distinct actors for each movie.
   - `AkaNames`: Aggregates all aliases of a person into a single string for easier display and joins.

2. **Main Query**:
   - Joins `RankedMovies` with `ActorCounts` to get the total number of distinct actors for each movie.
   - Joins with `AkaNames` to fetch all names associated with the actors in the movies and aggregates them.
   - Joins with `movie_info_idx` to grab additional information, filtering specifically for synopses.

3. **Filtering and Ordering**:
   - Filters for movies produced between 2000 and the current maximum production year.
   - Orders the results by production year and title, retrieving only the top 10 results based on the criteria.

4. **NULL Logic**:
   - Utilizes `COALESCE` to handle any potential NULL values from the actor count and display 0 instead. 

5. **String Aggregation**:
   - Uses `STRING_AGG` to combine multiple names into one for each actor, showing a comprehensive view of aliases.

This query not only showcases a variety of SQL constructs but also demonstrates handling multiple semantic aspects and edge cases.
