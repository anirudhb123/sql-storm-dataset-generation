WITH RECURSIVE hierarchy AS (
    SELECT 
        a.id AS person_id, 
        a.name AS actor_name, 
        a.md5sum,
        0 AS level
    FROM 
        aka_name a
    WHERE 
        a.name IS NOT NULL

    UNION ALL

    SELECT 
        c.person_id,
        a.name AS actor_name,
        a.md5sum,
        h.level + 1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        hierarchy h ON h.person_id = c.person_id
)

SELECT 
    t.title, 
    t.production_year, 
    COUNT(DISTINCT ci.person_id) AS num_cast,
    ARRAY_AGG(DISTINCT h.actor_name) AS actors,
    MAX(w.role_rank) AS highest_role_rank,
    COALESCE(m.note, 'No Note') AS movie_note
FROM 
    title t 
LEFT JOIN 
    complete_cast cc ON cc.movie_id = t.id
LEFT JOIN 
    cast_info ci ON ci.movie_id = t.id
LEFT JOIN 
    hierarchy h ON h.person_id = ci.person_id
LEFT JOIN 
    (SELECT person_id, 
            ROW_NUMBER() OVER (PARTITION BY role_id ORDER BY nr_order) AS role_rank 
     FROM 
            cast_info) w ON w.person_id = ci.person_id
LEFT JOIN 
    movie_info m ON m.movie_id = t.id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Note')
WHERE 
    t.production_year > 2000 
    AND (LOWER(t.title) LIKE '%action%' OR LOWER(t.title) LIKE '%drama%')
GROUP BY 
    t.id, m.note
ORDER BY 
    num_cast DESC, t.production_year DESC
LIMIT 50;

This SQL query showcases the following advanced concepts:

1. **Recursive CTE**: A recursive common table expression (CTE) to navigate through actors and their roles.
2. **LEFT JOINs**: Multiple outer joins to gather data from different tables, including handling NULL values effectively.
3. **Aggregation**: Counting distinct cast members and aggregating actor names into an array.
4. **Window Function**: Using `ROW_NUMBER()` to rank roles for each person.
5. **Subquery**: Fetching specific `info_type_id` from the `info_type` table.
6. **Complicated predicates**: Filter the movie titles based on year and keywords.
7. **COALESCE**: To handle possible NULL values in notes by providing a default.
8. **STRING Expressions**: Using `LOWER()` to perform case-insensitive searches.

The resulting dataset highlights movies with a focus on their cast, allowing performance benchmarking and examining the complexity of SQL syntax.
