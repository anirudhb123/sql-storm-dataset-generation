WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = (SELECT MAX(production_year) FROM aka_title)

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    coalesce(AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS avg_lead_role,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS year_rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
WHERE 
    a.name IS NOT NULL
    AND mt.production_year BETWEEN 2000 AND 2023 
GROUP BY 
    a.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    mt.production_year DESC, a.name
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;