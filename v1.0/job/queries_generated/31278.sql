WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        1 AS level
    FROM aka_title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    WHERE t.production_year >= 2000

    UNION ALL

    SELECT 
        mm.id AS movie_id,
        mt.title,
        mm.production_year,
        COALESCE(mk2.keyword, 'No Keyword') AS keyword,
        mh.level + 1
    FROM movie_hierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
    LEFT JOIN movie_keyword mk2 ON mt.id = mk2.movie_id
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    STRING_AGG(DISTINCT mh.title, ', ') AS movies,
    AVG(mh.production_year) AS avg_year,
    CASE 
        WHEN COUNT(DISTINCT mh.movie_id) > 5 THEN 'Prolific Actor'
        ELSE 'Emerging Talent' 
    END AS actor_status
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN complete_cast cc ON ci.movie_id = cc.movie_id
LEFT JOIN movie_hierarchy mh ON cc.movie_id = mh.movie_id
LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
WHERE a.name IS NOT NULL 
    AND a.name <> ''
GROUP BY a.name
HAVING COUNT(DISTINCT mc.movie_id) >= 2
ORDER BY movie_count DESC, avg_year ASC;

### Explanation
1. **Recursive CTE** (`movie_hierarchy`): The CTE constructs a movie hierarchy starting with movies from the year 2000, and recursively adds linked movies to the hierarchy.
2. **Aggregations**: The main query aggregates actor information by counting movies, concatenating movie titles, and averaging production years.
3. **CASE Statement**: A derived status of the actor based on the number of movies acted in.
4. **COALESCE**: Used to handle potential NULL values for keywords, replacing them with a default string (`'No Keyword'`). 
5. **LEFT JOIN**: Utilized to capture associations without missing out on movies that might not have linked movies (to keep the hierarchy intact).
6. **HAVING clause**: Filters out actors with fewer than two movies in the final result set.
7. **ORDER BY**: Incorporated to order results by the number of movies first, then by the average production year. 

This query is designed for performance benchmarking by testing the optimizer's handling of CTEs, joins, aggregations, string functions, and advanced filtering.
