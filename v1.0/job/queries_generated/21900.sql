WITH Recursive MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
)

SELECT 
    COALESCE(actor.name, 'Unknown Actor') AS actor_name,
    COUNT(DISTINCT DISTINCT cc.movie_id) AS movie_count,
    MAX(mh.production_year) AS latest_movie_year,
    ARRAY_AGG(DISTINCT k.keyword) FILTER (WHERE k.keyword IS NOT NULL) AS keywords,
    AVG(CASE 
            WHEN ci.nr_order IS NULL THEN 0 
            ELSE ci.nr_order 
        END) AS avg_order,
    ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank
FROM 
    aka_name a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
LEFT JOIN 
    MovieHierarchy mh ON cc.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = cc.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.person_id, actor_name
HAVING 
    COUNT(DISTINCT cc.movie_id) > 5 
    AND MAX(mh.production_year) <= EXTRACT(YEAR FROM CURRENT_DATE) 
ORDER BY 
    actor_rank
FETCH FIRST 10 ROWS ONLY;

-- Explanation of the SQL Constructs
-- - CTE MovieHierarchy is a recursive CTE to build a movie hierarchy based on links between movies.
-- - COALESCE is used to handle NULL actor names.
-- - COUNT, FILTER, and DISTINCT are applied to calculate a variety of aggregation metrics.
-- - AVG with a NULL handling case statement to compute average order with attention to NULL values.
-- - ROW_NUMBER() window function is used to rank actors based on their movie count.
-- - The main query retrieves actors who have appeared in more than 5 distinct movies up to the current year,
--   while employing outer joins to ensure completeness of results.
-- - The results are ordered and truncated for the top 10 actors based on their ranking.
