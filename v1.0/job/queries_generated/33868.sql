WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(NULLIF(c.role_id, 0), 'Unknown') AS role_id,
        COALESCE(NULLIF(c.nr_order, 0), 1) AS cast_order
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        ch.movie_id,
        m.title,
        m.production_year,
        COALESCE(NULLIF(c.role_id, 0), 'Unknown') AS role_id,
        COALESCE(NULLIF(c.nr_order, 0), 1) AS cast_order
    FROM 
        complete_cast ch
    JOIN 
        aka_title m ON ch.movie_id = m.id
    JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year < 2000
)
SELECT 
    title, 
    production_year, 
    role_id,
    COUNT(*) OVER(PARTITION BY role_id) AS total_cast,
    STRING_AGG(DISTINCT a.name, ', ') AS aliased_names
FROM 
    movie_hierarchy mh
LEFT JOIN 
    aka_name a ON mh.movie_id = a.person_id 
GROUP BY 
    title, production_year, role_id
HAVING 
    COUNT(*) FILTER (WHERE mh.cast_order > 1) > 5
ORDER BY 
    production_year DESC, 
    role_id;

This SQL query achieves the following:
1. It uses a recursive CTE (`movie_hierarchy`) to return a hierarchy of movies based on the `aka_title` and `cast_info` tables, filtering for production years from 2000 onward in the base case and earlier years in the recursive part.
2. It selects movie titles, production years, and roles, while applying COALESCE to handle NULLs and default values.
3. It employs a window function (`COUNT(*) OVER`) to count the total number of casts for each role, partitioned by role ID.
4. It joins the `aka_name` table to aggregate distinct aliased names for the movies.
5. The `HAVING` clause filters results to include only those roles where there are more than five cast members with an order greater than one.
6. Finally, the results are ordered by production year and role ID for better readability.
