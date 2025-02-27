WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id as movie_id,
        mt.title,
        mt.production_year,
        1 as level,
        NULL as parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year < 2000  

    UNION ALL 

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mh.movie_id
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.production_year >= 2000  
)

SELECT
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    cc.kind AS cast_type,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    SUM(CASE 
            WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') 
                THEN CAST(mi.info AS INTEGER) 
            ELSE 0 END
        ) AS total_budget
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
JOIN 
    comp_cast_type cc ON ci.person_role_id = cc.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = at.id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = ci.movie_id
WHERE 
    at.production_year IS NOT NULL
    AND ak.name IS NOT NULL
    AND (mi.info IS NULL OR mi.note IS NOT NULL)  
GROUP BY 
    ak.name, at.title, at.production_year, cc.kind
HAVING 
    COUNT(DISTINCT mc.company_id) > 5  
ORDER BY 
    at.production_year DESC,
    COUNT(DISTINCT mc.company_id) DESC,
    ak.name ASC;