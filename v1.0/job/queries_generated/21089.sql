WITH RECURSIVE TitleCTE AS (
    SELECT 
        t.id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(aka.name, 'Unknown') AS aka_name
    FROM 
        aka_title AS aka
    JOIN 
        title AS t ON aka.movie_id = t.id
    LEFT JOIN 
        (SELECT 
            DISTINCT movie_id,
            COUNT(*) OVER (PARTITION BY movie_id) AS role_count
         FROM 
            cast_info) AS role_info ON role_info.movie_id = t.id
    WHERE 
        role_info.role_count IS NOT NULL
      AND 
        (t.title LIKE 'A%' OR t.title LIKE 'B%')

    UNION ALL

    SELECT 
        t.id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(aka.name, 'Unknown')
    FROM 
        title AS t
    JOIN 
        TitleCTE AS recursive_cte ON t.id = recursive_cte.id
    WHERE 
        t.production_year < recursive_cte.production_year
)

SELECT 
    rc.aka_name,
    COUNT(DISTINCT rc.id) AS total_movies,
    MAX(t.production_year) AS latest_movie,
    MIN(t.production_year) AS earliest_movie,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id IN (SELECT id FROM title WHERE production_year >= 2000)) AS modern_roles,
    STRING_AGG(DISTINCT ck.keyword, ', ') AS keywords,
    COALESCE(SUM(CASE WHEN mn.info IS NOT NULL THEN 1 ELSE 0 END), 0) AS info_presence
FROM 
    TitleCTE AS rc
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = rc.id
LEFT JOIN 
    keyword AS ck ON ck.id = mk.keyword_id
LEFT JOIN 
    movie_info AS mn ON mn.movie_id = rc.id
GROUP BY 
    rc.aka_name
HAVING 
    COUNT(DISTINCT rc.id) > 5 AND
    (MAX(t.production_year) - MIN(t.production_year)) > 10
ORDER BY 
    total_movies DESC
FETCH FIRST 10 ROWS ONLY;

### Explanation:
1. **CTE (Common Table Expression)**: A recursive CTE named `TitleCTE` is created to list movies along with their alternative names. It also calculates the number of roles per movie using a `COUNT` window function.
2. **String Aggregation**: Uses `STRING_AGG` to concatenate different keywords associated with the movies from `movie_keyword` and `keyword`.
3. **Subquery in SELECT**: A correlated subquery counts modern roles from `cast_info` based on a criterion (production year >= 2000).
4. **Complex HAVING clause**: Specifies conditions on the number of distinct movies and their production year difference.
5. **LEFT JOINs**: Used multiple `LEFT JOINs` to retrieve optional data from other correlated tables and to handle NULLs gracefully.
6. **ORDER BY and FETCH**: Sorts the result by the total number of movies and limits the output to the top 10 records, adding performance implications in terms of how the query seeks to optimize data processing.

This query explores various SQL concepts ensuring strong syntactic use of SQL while tackling potential edge cases and null handling intricacies.
