WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS movie_rank,
        COALESCE(STRING_AGG(DISTINCT ak.name, ', ') FILTER (WHERE ak.name IS NOT NULL), 'Unknown') AS actor_names
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year IS NOT NULL AND t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
), 
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        ranked_movies AS rm
    WHERE 
        rm.movie_rank <= 3
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
final_output AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        COALESCE(mk.keywords, 'None') AS keywords,
        NULLIF(rm.actor_names, 'Unknown') AS main_actors
    FROM 
        filtered_movies AS fm
    LEFT JOIN 
        movie_keywords AS mk ON fm.movie_id = mk.movie_id
    LEFT JOIN 
        ranked_movies AS rm ON fm.movie_id = rm.movie_id
)
SELECT 
    fo.movie_id,
    fo.title,
    fo.production_year,
    fo.keywords,
    CASE 
        WHEN fo.main_actors IS NULL THEN 'No actors available'
        ELSE fo.main_actors 
    END AS main_actors
FROM 
    final_output AS fo
WHERE 
    EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = fo.movie_id
        AND mi.info ILIKE '%action%'
    )
ORDER BY 
    fo.production_year DESC,
    fo.title;

This query performs the following advanced operations:

1. **Common Table Expressions (CTEs)**: It utilizes multiple CTEs to calculate ranked movies based on actor count per production year and filters those down to the top three per year.

2. **String Aggregation**: It combines actor names and associated keywords into a single string for ease of reading.

3. **Outer Joins**: Leveraging left joins to ensure that all movies in the filtered list are included even if they have no associated keywords or actor names.

4. **Null Handling**: It uses `COALESCE` and `NULLIF` to manage null values effectively, providing meaningful output when data is sparse.

5. **Correlated Subquery**: It includes a correlated subquery in the `WHERE` clause to filter movies that contain a specific keyword in their information.

6. **Advanced Filtering and Grouping**: It groups data effectively while also ensuring no duplicates in the names and keywords.

7. **Output Conditioning**: The output conditionally replaces null actor names with a default message to maintain clarity.

This complex query aims to showcase efficient SQL practices while tackling potential NULL handling and aggregation challenges within a specific filmmaking context.
