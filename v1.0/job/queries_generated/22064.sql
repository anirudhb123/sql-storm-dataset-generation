WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mlink.linked_movie_id, 0) AS linked_movie_id,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    LEFT JOIN movie_link mlink ON m.id = mlink.movie_id

    UNION ALL

    SELECT 
        m.id,
        m.title,
        COALESCE(mlink.linked_movie_id, 0),
        m.production_year,
        mh.level + 1
    FROM
        movie_hierarchy mh
    JOIN movie_link mlink ON mh.linked_movie_id = mlink.movie_id
    JOIN aka_title m ON mlink.linked_movie_id = m.id
)
SELECT 
    ak.name,
    ak.id AS aka_id,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    title.title AS movie_title,
    title.production_year,
    COUNT(DISTINCT cc.person_id) AS actor_count,
    AVG(CASE WHEN cc.nr_order IS NOT NULL THEN cc.nr_order ELSE 0 END) AS avg_order,
    MAX(CASE WHEN cc.note IS NOT NULL THEN LENGTH(cc.note) ELSE 0 END) AS max_note_length,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS rank_by_actor_count
FROM
    aka_name ak
LEFT JOIN cast_info cc ON ak.person_id = cc.person_id
LEFT JOIN movie_companies mc ON mc.movie_id = cc.movie_id
LEFT JOIN company_type c ON c.id = mc.company_type_id
LEFT JOIN movie_keyword mk ON mk.movie_id = mc.movie_id
LEFT JOIN keyword k ON k.id = mk.keyword_id
LEFT JOIN movie_hierarchy mh ON mh.movie_id = cc.movie_id
LEFT JOIN title title ON title.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND (cc.note IS NULL OR cc.note NOT LIKE 'deleted%')
    AND title.production_year BETWEEN 1990 AND 2023
GROUP BY 
    ak.id, title.id
HAVING 
    COUNT(DISTINCT cc.person_id) > 0
ORDER BY 
    rank_by_actor_count, title.production_year DESC;

### Explanation:
1. **Common Table Expressions (CTE)**: The `movie_hierarchy` CTE is a recursive CTE that builds a hierarchy of movies based on links to other movies.

2. **LEFT JOINs**: Multiple `LEFT JOIN` operations bring in additional data from related tables, ensuring that even movies without certain links will still appear in results.

3. **Aggregation Functions**: 
   - `GROUP_CONCAT` is used to create a string of keywords associated with the movies.
   - `COUNT`, `AVG`, and `MAX` are used to gather statistics for actors related to the movies.

4. **CASE Statements**: These handle NULL logic:
   - For `avg_order`, it replaces NULL `nr_order` with 0 for averaging purposes.
   - For `max_note_length`, it calculates the length of notes, defaulting to 0 if NULL.

5. **Window Functions**: `ROW_NUMBER` partitions the result set by `aka_id` and ranks by actor count.

6. **HAVING Clause**: Filters groups that have at least one actor, ensuring only relevant entries are kept in the final result.

7. **WHERE Clause**: Includes conditions to filter out null names and restricts production years.

8. **Complexity**: The query reflects a sophisticated structure and combines various SQL constructs that could be considered unusual or intricate, focusing on performance benchmarking across a complex dataset.
