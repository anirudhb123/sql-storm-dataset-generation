WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mlink.linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link mlink ON mt.id = mlink.movie_id
    WHERE 
        mt.production_year = 2023
        
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mlink.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        aka_title mt ON mh.linked_movie_id = mt.id
    LEFT JOIN 
        movie_link mlink ON mt.id = mlink.movie_id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT ci.movie_id) AS movies_count,
    AVG(ti.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') FILTER (WHERE kw.keyword IS NOT NULL) AS keywords,
    COALESCE(NULLIF(cn.name, ''), 'Unknown Company') AS company_name
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    movie_info mi ON ci.movie_id = mi.movie_id
JOIN 
    movie_info_idx ti ON ti.movie_id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = ci.movie_id
WHERE 
    ci.nr_order < 5
    AND cc.status_id IN (1, 2) -- 1 - Complete, 2 - Released
GROUP BY 
    ak.name, cn.name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 2
ORDER BY 
    movies_count DESC,
    avg_production_year ASC;

This SQL query constructs a recursive Common Table Expression (CTE) `movie_hierarchy` to find all linked movies from those produced in 2023. It joins multiple tables to gather data about actors, movies, keywords, and associated companies. The final output aggregates this data to provide insights into actors with a count of movies, the average production year of those movies, a list of keywords, and the company name, applying filtering on presence and non-empty elements while sorting the results effectively.
