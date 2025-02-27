WITH RECURSIVE actor_hierarchy AS (
    SELECT c.movie_id, a.name AS actor_name, a.person_id, 
           1 AS depth, 
           CAST(a.name AS text) AS path
    FROM cast_info AS c
    JOIN aka_name AS a ON c.person_id = a.person_id
    WHERE c.role_id IN (SELECT id FROM role_type WHERE role LIKE '%actor%')
    
    UNION ALL
    
    SELECT c.movie_id, a.name AS actor_name, a.person_id, 
           ah.depth + 1 AS depth, 
           ah.path || ' -> ' || a.name
    FROM cast_info AS c
    JOIN aka_name AS a ON c.person_id = a.person_id
    JOIN actor_hierarchy AS ah ON c.movie_id = ah.movie_id
    WHERE c.role_id IN (SELECT id FROM role_type WHERE role LIKE '%actor%')
)
SELECT 
    m.title,
    m.production_year,
    COUNT(DISTINCT ch.actor_name) AS unique_actor_count,
    MAX(ah.depth) AS max_depth,
    STRING_AGG(DISTINCT ah.actor_name, ', ') AS actor_path,
    COALESCE(k.keyword, 'No keyword') AS keyword,
    COUNT(DISTINCT mc.company_id) AS production_company_count,
    AVG(str_length(m.info)) AS avg_info_length
FROM
    title AS m
LEFT JOIN
    complete_cast AS cc ON m.id = cc.movie_id
LEFT JOIN
    actor_hierarchy AS ah ON cc.subject_id = ah.person_id
LEFT JOIN
    movie_keyword AS mk ON m.id = mk.movie_id
LEFT JOIN
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN
    movie_companies AS mc ON m.id = mc.movie_id
LEFT JOIN
    movie_info AS mi ON m.id = mi.movie_id
GROUP BY 
    m.title, m.production_year, k.keyword
HAVING 
    COUNT(DISTINCT ah.actor_name) > 5 
    OR MAX(ah.depth) > 3
ORDER BY 
    unique_actor_count DESC, 
    production_year DESC
LIMIT 100;

### Explanation:
- **CTE (Common Table Expression)**: `actor_hierarchy` recursively builds a hierarchy of actors associated with the films.
- **Joins**: Utilizes several outer joins to ensure comprehensive data retrieval including movies, their keywords, and production companies.
- **Aggregations**: 
  - Counts unique actors,
  - Calculates maximum depth of actor relationships,
  - Concatenates a list of actor names,
  - Counts production companies,
  - Computes average length of information text.
- **Condition**: Filters results based on the unique count of actors and their maximum depth using the `HAVING` clause.
- **String Aggregation**: Utilizes `STRING_AGG` for listing actor paths, showcasing complex string operations.
- **NULL Handling**: Uses `COALESCE` to replace potential NULL keyword entries with a placeholder.
- **Bizarre semantics**: Incorporates predicates that may yield unintuitive results (e.g., depths of relationships deeper than normal or unique counts higher than thresholds), ensuring some corner cases.
- **Final Ordering**: Orders the results by actor count and production year, demonstrating a layered query structure.
