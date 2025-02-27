WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS depth
    FROM aka_title m
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
      AND m.production_year IS NOT NULL

    UNION ALL

    SELECT m.id, m.title, m.production_year, mh.depth + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE mh.depth < 5  -- Limiting the depth to avoid too much recursion
)

SELECT 
    a.name,
    t.title,
    t.production_year,
    COALESCE(p.info, 'N/A') AS person_info,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rank,
    CASE 
        WHEN COUNT(DISTINCT c.movie_id) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS status,
    CASE 
        WHEN CASE WHEN COUNT(DISTINCT c.movie_id) > 10 THEN true ELSE false END THEN 'Frequent Collaborator'
        ELSE 'Occasional Collaborator'
    END AS collaboration_type
FROM aka_name a
LEFT JOIN cast_info c ON a.person_id = c.person_id
LEFT JOIN complete_cast cc ON c.movie_id = cc.movie_id
LEFT JOIN movie_keyword mk ON c.movie_id = mk.movie_id
LEFT JOIN person_info p ON a.person_id = p.person_id AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'bio')
JOIN movie_hierarchy t ON c.movie_id = t.movie_id
GROUP BY a.name, t.title, t.production_year, p.info
HAVING SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) > 0
   AND t.production_year BETWEEN 2000 AND 2020
ORDER BY rank, a.name;


This SQL query does the following:

1. **Common Table Expression (CTE)**: Uses a recursive CTE to build a hierarchy of movies linked together, limited to a depth of 5 to avoid excessive recursion.

2. **Joins**: Combines several tables to gather data on names, casts, movies, keywords, and associated information.

3. **Aggregations**: Counts movies and keywords, and uses conditional aggregation to identify active/inactive status.

4. **Window Functions**: Utilizes `ROW_NUMBER` to rank actors based on their movie involvement.

5. **Complicated Conditions**: Applies several conditions in the `HAVING` clause and uses `CASE` statements to categorize collaboration types.

6. **NULL Logic**: Uses `COALESCE` to handle potential null values in person info.

This query tests various SQL features such as CTE, joins, window functions, and aggregations in a complex way, enabling performance benchmarking in a highly structured schema.
