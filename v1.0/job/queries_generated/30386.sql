WITH RECURSIVE movie_hierarchy AS (
    -- Base case: Select all movies as the starting point
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020

    UNION ALL

    -- Recursive case: Join with movie_link to construct hierarchy
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.title AS original_movie,
    mh.production_year AS original_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(CASE 
        WHEN mii.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') 
        THEN CAST(mii.info AS DECIMAL) 
        ELSE NULL 
    END) AS average_budget,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    SUM(CASE 
        WHEN r.role = 'Actress' THEN 1 
        ELSE 0 
    END) AS female_leads,
    MAX(mh.level) AS max_hierarchy_level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_info mii ON mh.movie_id = mii.movie_id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1 
ORDER BY 
    original_year DESC, original_movie;
