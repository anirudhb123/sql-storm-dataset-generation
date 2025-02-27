
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies,
    COUNT(ci.id) AS total_cast,
    COUNT(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 END) AS roles_filled
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ci.nr_order IS NOT NULL
GROUP BY 
    t.title, a.name, t.id, t.production_year
ORDER BY 
    t.production_year DESC, total_cast DESC
LIMIT 50;
