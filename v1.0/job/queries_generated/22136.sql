WITH Recursive CastDetails AS (
    SELECT 
        c.movie_id,
        a.name,
        a.id AS actor_id,
        ROW_NUMBER() OVER(PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order,
        COALESCE(NULLIF(a.name, ''), 'Unknown Actor') AS actor_name
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),
TitleDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        DENSE_RANK() OVER(ORDER BY t.production_year DESC) AS rank_order
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
)
SELECT 
    td.title,
    td.production_year,
    GROUP_CONCAT(DISTINCT cd.actor_name ORDER BY cd.actor_order) AS actors_list,
    AVG(IFNULL(sub.movie_rating, 0)) AS average_rating,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    COALESCE(NULLIF(td.kind_id, 0), 'Type Unknown') AS movie_type
FROM 
    TitleDetails td
LEFT JOIN 
    CastDetails cd ON td.title_id = cd.movie_id
LEFT JOIN 
    (SELECT 
         mi.movie_id, 
         AVG(MOOD(mi.info)) AS movie_rating
     FROM movie_info mi
     WHERE mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
     GROUP BY mi.movie_id) sub ON td.title_id = sub.movie_id
LEFT JOIN 
    movie_keyword mk ON td.title_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
WHERE 
    td.production_year >= 2000
AND 
    (cd.actor_name IS NOT NULL OR td.production_year IS NOT NULL)
GROUP BY 
    td.title, 
    td.production_year, 
    td.kind_id
HAVING 
    COUNT(DISTINCT cd.actor_id) > 1
ORDER BY 
    td.production_year DESC, 
    average_rating DESC
LIMIT 100;

### Explanation of Query Constructs:
1. **Common Table Expressions (CTEs)**: 
   - `CastDetails`: Retrieves actor names with their orders for each movie and handles potentially null names.
   - `TitleDetails`: Gathers movie titles with unique ranking based on production years.
  
2. **Window Functions**: 
   - `ROW_NUMBER()` is used in `CastDetails` for ordering actors within each movie.
   - `DENSE_RANK()` in `TitleDetails` provides a ranking of movies by year.

3. **Outer Joins**: 
   - `LEFT JOIN` on multiple tables to ensure that we retain movies that might not have associated cast or ratings.

4. **Coalesce and Null Handling**: 
   - Used to manage potential null values in title types and actor names to provide sensible defaults.

5. **Subqueries**: 
   - A subquery computes average movie ratings based on information type, ensuring only relevant movies are evaluated.

6. **Complicated Predicates**: 
   - Conditions such as non-null constraints and combinations in `WHERE` and `HAVING` for filtering results.

7. **String Aggregation**: 
   - `GROUP_CONCAT` used to concatenate actor names for each movie into a single string.

8. **Set Operators**: 
   - `COUNT(DISTINCT ...)` is applied to count unique elements (keywords) while considering null logic.

9. **Bizarre Logic**: 
   - The filtering and summarizing on various movie metrics while ensuring that there are at least two actors present in a title adds an interesting edge to the selection criteria. 

10. **Ordering and Limit**: 
    - The final results are sorted by production year and average rating with a limit imposed for benchmarking performance.
