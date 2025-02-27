WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 3
),
cast_with_roles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ' ORDER BY it.id) AS all_info,
        COUNT(DISTINCT mi.note) AS note_count
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ci.actor_name,
    ci.role,
    mis.all_info,
    mis.note_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_with_roles ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    movie_info_summary mis ON mh.movie_id = mis.movie_id
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
    AND (ci.role IS NOT NULL OR mis.note_count > 0) -- include movies with roles or info
ORDER BY 
    mh.production_year DESC,
    mh.title ASC,
    ci.role_order ASC;

This SQL query accomplishes the following:

1. **Recursive CTE**: The `movie_hierarchy` CTE generates a hierarchy of movies (up to 3 levels deep) linked by their relationships in the `movie_link` table.

2. **Role with Window Functions**: The `cast_with_roles` CTE gathers the actors and their roles per movie while assigning an order to their appearances using `ROW_NUMBER()`.

3. **Aggregation**: The `movie_info_summary` CTE aggregates movie information into a single string per movie while counting distinct notes.

4. **Final Selection**: The main query selects relevant movie information, joining on the previously defined CTEs and applying a date filter for production years.

5. **Outer Joins and Complicated Conditions**: Left joins ensure that even movies without casts or additional info are included, and the final filter includes movies either with a cast or any available information.

Ultimately, the query produces a robust overview of movies added in the 21st century, their cast members, roles, and any relevant information.
