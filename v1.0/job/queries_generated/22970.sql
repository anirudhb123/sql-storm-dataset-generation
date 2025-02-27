WITH RECURSIVE title_hierarchy AS (
    SELECT t.id AS title_id, 
           t.title, 
           t.production_year, 
           COALESCE(ct.kind, 'Unknown') AS kind, 
           1 AS level
    FROM title t
    LEFT JOIN kind_type ct ON t.kind_id = ct.id
    UNION ALL
    SELECT t2.id AS title_id, 
           t2.title, 
           t2.production_year, 
           COALESCE(ct.kind, 'Unknown') AS kind, 
           th.level + 1
    FROM title_hierarchy th
    JOIN title t2 ON th.title_id = t2.episode_of_id 
    LEFT JOIN kind_type ct ON t2.kind_id = ct.id
),
cast_data AS (
    SELECT ci.movie_id, 
           ak.name AS actor_name, 
           rt.role, 
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rt ON ci.role_id = rt.id
),
movie_keywords AS (
    SELECT mk.movie_id, 
           STRING_AGG(mk.keyword_id::text, ',') AS keyword_ids
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT th.title, 
       th.production_year, 
       th.kind, 
       cd.actor_name,
       cd.role, 
       cd.role_order,
       COALESCE(mk.keyword_ids, 'No Keywords') AS keywords,
       CASE 
           WHEN th.level > 1 THEN 'Spin-off' 
           ELSE 'Original' 
       END AS title_type,
       (SELECT COUNT(*) 
        FROM complete_cast cc 
        WHERE cc.movie_id = th.title_id AND cc.status_id IS NOT NULL) AS complete_cast_count
FROM title_hierarchy th
LEFT JOIN cast_data cd ON th.title_id = cd.movie_id
LEFT JOIN movie_keywords mk ON th.title_id = mk.movie_id
WHERE (th.production_year > 2000 AND th.production_year < 2023) 
  OR th.kind != 'Short'
ORDER BY th.production_year DESC, 
         th.title, 
         cd.role_order
LIMIT 100
OFFSET 50;

### Explanation of Constructs Used:

1. **Common Table Expressions (CTEs)**: Three CTEs (`title_hierarchy`, `cast_data`, `movie_keywords`) are used to break down the logic into manageable parts.
   - `title_hierarchy`: Recursively builds a hierarchy of titles, especially for series and their episodes.
   - `cast_data`: Gathers information about the cast members of each movie, including their roles and their order.
   - `movie_keywords`: Collects keywords associated with each movie.

2. **String Aggregation**: Uses `STRING_AGG` to combine multiple keywords into a single field per movie.

3. **Window Functions**: Applies `ROW_NUMBER()` to sequence the roles.

4. **Joins**: Employs several types of joins (LEFT JOINs) to gather necessary information across tables. 

5. **Complex Predicates**: Uses a combination of conditions to filter results based on the title's production year and kind.

6. **NULL Handling**: Utilizes `COALESCE` to handle NULL values gracefully, providing default values when necessary.

7. **Subquery**: Incorporates a correlated subquery to count complete casts for each title.

8. **Bizarre Logic**: The use of a level-based determination for distinguishing 'Spin-off' from 'Original' titles.

9. **Limit & Offset**: Implements pagination on the results to focus on a subset of the output. 

This query serves as a robust performance benchmark combining complex SQL features and intricate logic, making it ideal for testing SQL engine performance under advanced scenarios.
