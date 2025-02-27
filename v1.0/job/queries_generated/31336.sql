WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t 
    JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    WHERE 
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Production Company')
      
    UNION ALL

    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        mh.level + 1 AS level
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.movie_id
    WHERE 
        mh.level < 3  -- Limit to 3 levels of hierarchy
)

SELECT 
    t.title AS Movie_Title,
    t.production_year AS Production_Year,
    ak.name AS Actor_Name,
    COUNT(DISTINCT mc.company_id) AS Production_Companies,
    SUM(CASE WHEN mii.note IS NOT NULL THEN 1 ELSE 0 END) AS Additional_Info_Count,
    ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS Rank
FROM 
    movie_hierarchy mh
JOIN 
    title t ON mh.movie_id = t.id
LEFT JOIN 
    cast_info c ON t.id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    movie_info_idx mii ON t.id = mii.movie_id
WHERE 
    ak.name IS NOT NULL
    AND t.production_year IS NOT NULL
GROUP BY 
    t.title, 
    t.production_year, 
    ak.name
HAVING 
    COUNT(DISTINCT c.person_role_id) > 1  -- Only select titles with more than one role
ORDER BY 
    t.production_year DESC, 
    Movie_Title
LIMIT 100;

-- Note: This query evaluates the performance benchmarks based on linked movies and their hierarchy, 
-- while also calculating additional metrics such as the number of production companies and additional info count. 
