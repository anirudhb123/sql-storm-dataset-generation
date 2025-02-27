WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS title_count
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
),
cast_with_roles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        COALESCE(rt.role, 'Unknown Role') AS role,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS cast_count
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
),
popular_movies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT c.person_id) AS unique_cast_count
    FROM 
        aka_title mt
    INNER JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    GROUP BY 
        mt.title, mt.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 10
)
SELECT 
    rt.title,
    rt.production_year,
    rt.title_rank,
    CASE 
        WHEN rt.title_count > 5 THEN 'Multiple Titles'
        ELSE 'Few Titles'
    END AS title_distribution,
    COALESCE(cwr.role, 'No Role') AS actor_role,
    pm.unique_cast_count
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_with_roles cwr ON rt.title_id = cwr.movie_id
LEFT JOIN 
    popular_movies pm ON rt.title = pm.title AND rt.production_year = pm.production_year
WHERE 
    rt.title_rank = 1 OR pm.unique_cast_count IS NOT NULL
ORDER BY 
    rt.production_year DESC, rt.title;

### Explanation of the SQL Query:

1. **CTE - ranked_titles**: This common table expression (CTE) ranks each movie title based on its production year and assigns a rank. Titles produced in the same year will have consecutive rank numbers.

2. **CTE - cast_with_roles**: This CTE gathers information about cast members and their roles for each movie, using a left join to fall back to 'Unknown Role' if no corresponding role exists. It also counts how many cast members are associated with each movie.

3. **CTE - popular_movies**: This CTE identifies movies that have a significant cast (greater than 10 unique cast members). It groups by the movie title and its production year.

4. **Final SELECT**: The main query selects data from the `ranked_titles` CTE and joins it with `cast_with_roles` and `popular_movies`. It uses a `CASE` statement to categorize the distribution of titles based on the number of titles produced within a year.

5. **WHERE Clause**: The final output is filtered to include either the top-ranked title of each year or those that are part of the popular movies.

6. **Order By**: The output is sorted by the production year in descending order and the title name.

This SQL structure showcases various complex SQL elements such as window functions, multiple joins, CTEs, aggregation, and conditional logic, while incorporating NULL handling and unique aggregations.
