WITH RECURSIVE cast_hierarchy AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        a.id AS actor_id,
        1 AS depth
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.nr_order = 1  -- Starting with the first actor in the cast

    UNION ALL

    SELECT 
        c.movie_id,
        a.name AS actor_name,
        a.id AS actor_id,
        ch.depth + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        cast_hierarchy ch ON c.movie_id = ch.movie_id AND c.nr_order = ch.depth + 1
)

SELECT 
    t.title,
    t.production_year,
    STRING_AGG(ch.actor_name, ', ') AS cast_list,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(mo.info IS NOT NULL) AS info_entries,
    ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS row_num
FROM 
    title t
LEFT JOIN 
    cast_hierarchy ch ON t.id = ch.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    movie_info mo ON t.id = mo.movie_id AND mo.info_type_id IN (
        SELECT id FROM info_type WHERE info LIKE 'Plot%'
    )
WHERE 
    t.production_year >= 2000
    AND (t.kind_id IS NOT NULL OR t.kind_id IN (1, 2, 3)) 
GROUP BY 
    t.id, t.title, t.production_year
HAVING 
    COUNT(DISTINCT ch.actor_id) > 5
ORDER BY 
    t.production_year DESC, t.title;

### Explanation of Query Components:

1. **Common Table Expression (CTE)**: The `cast_hierarchy` CTE recursively retrieves actors for each movie, beginning with the first actor. It tracks the depth, which allows for representing multi-level cast structures.

2. **Main Query**: 
   - Joins the essential tables: `title`, `cast_hierarchy`, `movie_keyword`, `keyword`, `movie_companies`, and `movie_info`.
   - It computes aggregates such as:
     - `STRING_AGG` for combining actor names into a single string.
     - `COUNT(DISTINCT ...)` for counting unique keywords and company IDs.
     - `SUM(...)` to count non-null entries of movie information.
   - Utilizes a window function `ROW_NUMBER()` to assign a unique number to each row per movie.

3. **WHERE Clause**: Applies conditions on the production year and ensures the movie kind is valid.

4. **HAVING Clause**: Filters for movies that have more than 5 distinct actors in their cast.

5. **Order By**: Results are sorted by production year (descending) and title.

This query aims to gather essential benchmarking metrics on movies produced after 2000, showcasing an elaborate use of SQL features, including window functions, aggregates, recursive CTEs, and various joins.
