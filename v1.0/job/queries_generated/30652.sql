WITH RECURSIVE expanded_cast AS (
    SELECT c.movie_id, c.person_id, 1 AS depth
    FROM cast_info c
    WHERE c.role_id = (SELECT id FROM role_type WHERE role = 'lead')
    
    UNION ALL
    
    SELECT c.movie_id, c.person_id, e.depth + 1
    FROM expanded_cast e
    JOIN cast_info c ON e.movie_id = c.movie_id
    WHERE c.role_id <> (SELECT id FROM role_type WHERE role = 'lead')
)
SELECT 
    t.title,
    a.name AS lead_actor,
    COALESCE(cc.kind, 'Unknown') AS company_type,
    m.production_year,
    (SELECT COUNT(*)
        FROM movie_keyword mk 
        JOIN keyword k ON mk.keyword_id = k.id 
        WHERE mk.movie_id = t.id) AS keyword_count,
    COUNT(ec.person_id) AS additional_cast_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(ec.person_id) DESC) AS rank_by_cast_count
FROM title t
JOIN movie_info m ON m.movie_id = t.id
JOIN aka_title at ON at.movie_id = t.id
JOIN expanded_cast ec ON ec.movie_id = t.id
LEFT JOIN movie_companies mc ON mc.movie_id = t.id
LEFT JOIN company_name cn ON cn.id = mc.company_id
LEFT JOIN company_type cc ON cc.id = mc.company_type_id
JOIN aka_name a ON a.person_id = ec.person_id
LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN keyword k ON k.id = mk.keyword_id
WHERE m.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
AND m.info IS NOT NULL
GROUP BY t.title, a.name, m.production_year, cc.kind
HAVING COUNT(ec.person_id) > 0
ORDER BY m.production_year DESC, rank_by_cast_count ASC;

This query performs a variety of advanced SQL techniques, including:
- A recursive Common Table Expression (CTE) to build a hierarchy of the cast starting from leads.
- Use of COALESCE to handle potential NULL values in the company type.
- Use of subqueries to count keywords for each movie.
- A window function, RANK, to rank movies based on their cast count within each production year.
- Aggregation with STRING_AGG to combine keywords into a single string.
- A LEFT JOIN to include information about movie companies, handling NULLs effectively.
- Filtering with HAVING to get only those movies with additional cast members. 

Overall, the query benchmarks performance with complex joins, aggregations, and window functions while providing detailed output about movies featuring a significant number of actors and specific keyword data.
