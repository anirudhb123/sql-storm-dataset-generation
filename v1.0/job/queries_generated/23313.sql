WITH RECURSIVE TitleHierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.episode_of_id,
        0 AS hierarchy_level
    FROM 
        title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        th.title_id AS episode_of_id,
        th.hierarchy_level + 1
    FROM 
        title t
    INNER JOIN 
        TitleHierarchy th ON t.episode_of_id = th.title_id
)
SELECT 
    ak.name AS actor_name,
    ti.title AS movie_title,
    ti.production_year,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY ti.production_year DESC) AS movie_rank,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = ti.id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')) AS box_office_count
FROM 
    aka_name ak
INNER JOIN 
    cast_info ci ON ak.person_id = ci.person_id
INNER JOIN 
    aka_title at ON ci.movie_id = at.movie_id
INNER JOIN 
    TitleHierarchy ti ON at.movie_id = ti.title_id
LEFT JOIN 
    movie_companies mc ON ti.title_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON ti.title_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ti.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature film')
    AND ci.nr_order IS NOT NULL
    AND COALESCE(mc.note, '') NOT LIKE '%uncredited%'
GROUP BY 
    ak.name, ti.title, ti.production_year, ak.person_id
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    movie_rank DESC, num_companies DESC
LIMIT 10 OFFSET 5;

### Explanation:
1. **CTE - TitleHierarchy**: This recursive common table expression identifies the hierarchy of movie titles, accounting for both standalone titles and episodes.
2. **Main Query**: 
   - Joins tables for actors (aka_name), cast information (cast_info), title information (aka_title and TitleHierarchy), and company associations (movie_companies).
   - Uses `LEFT JOIN`s to capture additional data like keywords from `movie_keyword` and `keyword`.
   - Implements a `WHERE` filter to ensure that only "feature films" are considered and handles NULL logic through the `COALESCE` function to prevent counting companies with a specific uncredited note.
3. **Aggregations and Calculations**:
   - Uses `COUNT(DISTINCT ...)` to count the number of companies associated with each movie.
   - Uses `ROW_NUMBER()` window function for ranking movies produced by each actor based on release year.
   - The subquery in the SELECT clause counts the number of box office entries linked to each title.
4. **Filtering**: The `HAVING` clause ensures only titles associated with companies are returned.
5. **Pagination**: Limits the results to a specific range (10 records after skipping 5) to facilitate performance benchmarking. 

This query is complex and employs a variety of SQL features and logic to demonstrate thoroughness in performance benchmarking across multiple dimensions of the provided schema.
