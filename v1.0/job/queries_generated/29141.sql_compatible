
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
)

SELECT 
    ak.name AS actor_name,
    ak.id AS actor_id,
    rt.title AS movie_title,
    rt.production_year,
    ct.kind AS company_type,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    RankedTitles rt ON ci.movie_id = rt.title_id
JOIN 
    movie_companies mc ON rt.title_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    ak.name LIKE '%Smith%'
    AND rt.production_year BETWEEN 2000 AND 2020
GROUP BY 
    ak.name, ak.id, rt.title, rt.production_year, ct.kind
ORDER BY 
    actor_name, rt.production_year DESC;
