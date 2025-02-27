WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER(PARTITION BY mt.production_year ORDER BY mt.production_year DESC, mt.title) AS year_rank
    FROM 
        aka_title AS mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('feature', 'movie'))
),
PersonRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_type,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info AS ci
    INNER JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    INNER JOIN 
        role_type AS rt ON rt.id = ci.role_id
    WHERE 
        ci.nr_order BETWEEN 1 AND 5
    GROUP BY 
        ci.movie_id, ak.name, rt.role
),
MovieDetails AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        pr.actor_name,
        pr.role_type,
        pr.role_count
    FROM 
        RankedMovies AS r
    LEFT JOIN 
        PersonRoles AS pr ON r.movie_id = pr.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(md.role_type, 'Unknown Role') AS role_type,
    SUM(md.role_count) OVER(PARTITION BY md.production_year ORDER BY md.title) AS cumulative_roles
FROM 
    MovieDetails AS md
WHERE
    md.production_year IS NOT NULL 
    AND (EXISTS (SELECT 1 FROM movie_keyword WHERE movie_id = md.movie_id AND keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%Drama%'))
         OR md.production_year > 2000)
ORDER BY 
    md.production_year DESC, md.title
FETCH FIRST 10 ROWS ONLY;

### Explanation of the SQL Query Constructs:
1. **Common Table Expressions (CTEs)**: 
   - **`RankedMovies`:** This CTE categorizes the movies by production year and ranks them by title.
   - **`PersonRoles`:** This aggregates actor roles, filtering for primary roles (first 5).
   - **`MovieDetails`:** Joins the previous CTEs to provide a comprehensive view of movie titles and their associated actor roles.

2. **Joins**: 
   - Utilizes both inner and outer joins to ensure comprehensive data collection from the related tables.

3. **Window Functions**: 
   - **`ROW_NUMBER()`** is used to rank movies within their production year.
   - **`SUM() OVER()`** calculates a running total of roles count by production year.

4. **Correlated Subqueries**: 
   - Checks for 'Drama' keywords on movies in a correlated manner to filter results.
  
5. **COALESCE Function**: 
   - Handles NULL values by providing default text for missing actor names or roles.

6. **Complicated Predicate**: 
   - The `WHERE` clause contains both EXISTS and conditions combining different filtering requirements (years and keywords).

7. **Set Operator**: 
   - Could be easily extended to leverage `UNION` if needed to include data from another source or CTE.

8. **String Expressions**: 
   - The query uses a LIKE condition to filter keyword searches, demonstrating string matching capabilities.

9. **NULL Logic**: 
   - The use of `COALESCE` and conditions checking for NULLs help ensure the query is robust against incomplete data.

This query is designed not only to fetch data but also to demonstrate various SQL features suitable for performance benchmarking by stressing different aspects of SQL query handling and optimization.
