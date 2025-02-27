WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1 -- Assuming '1' indicates a main movie

    UNION ALL

    SELECT 
        mm.id,
        mm.title,
        mm.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mm ON ml.linked_movie_id = mm.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    c.role_id,
    COUNT(DISTINCT cc.company_id) AS companies_involved,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY mt.production_year DESC) AS movie_rank,
    SUM(CASE WHEN pi.info_type_id = 1 THEN 1 ELSE 0 END) AS awards_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title mt ON c.movie_id = mt.id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    c.note IS NULL 
    AND mt.production_year BETWEEN 2000 AND 2023
    AND (cn.country_code IS NULL OR cn.country_code != 'USA')
GROUP BY 
    ak.name, mt.title, mt.production_year, c.role_id
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    movie_rank, mt.production_year DESC;
