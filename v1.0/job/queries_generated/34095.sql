WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        1 AS level
    FROM 
        cast_info ca
    WHERE 
        ca.note IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ca.person_id,
        ca.movie_id,
        ah.level + 1
    FROM 
        cast_info ca
    JOIN 
        ActorHierarchy ah ON ca.movie_id = ah.movie_id
    WHERE 
        ca.person_id <> ah.person_id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    ci.note AS role_note,
    COUNT(DISTINCT c.company_id) AS total_companies,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    CASE 
        WHEN mt.production_year < 2000 THEN 'Classic'
        WHEN mt.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year DESC) AS movie_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mt.id
LEFT JOIN 
    company_name c ON mc.company_id = c.id

LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id

WHERE 
    ak.name IS NOT NULL
    AND mt.production_year IS NOT NULL
    AND ci.role_id IN (SELECT id FROM role_type WHERE role LIKE '%Actor%')
    AND (mt.production_year > 1990 OR ak.surname_pcode IS NOT NULL)
GROUP BY 
    ak.name, mt.title, mt.production_year, ci.note
HAVING 
    COUNT(DISTINCT c.company_id) > 1 
    AND AVG(COALESCE(ci.nr_order, 0)) > 1
ORDER BY 
    movie_rank DESC
LIMIT 100;
