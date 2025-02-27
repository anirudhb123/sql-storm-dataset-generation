WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        mh.depth + 1 AS depth
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.movie_id = a.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year AS year,
    COUNT(DISTINCT mc.company_id) AS companies_count,
    LISTAGG(DISTINCT c.name, '; ') WITHIN GROUP (ORDER BY c.name) AS company_names,
    SUM(CASE WHEN mki.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year DESC) AS rn
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword mki ON mk.keyword_id = mki.id
LEFT JOIN 
    movie_hierarchy mh ON mt.id = mh.movie_id -- Adding recursive hierarchy
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    rn, year DESC;
