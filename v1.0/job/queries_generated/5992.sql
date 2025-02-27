SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.kind AS comp_kind,
    k.keyword AS movie_keyword,
    GROUP_CONCAT(DISTINCT p.info SEPARATOR '; ') AS person_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND ct.kind LIKE 'Production'
GROUP BY 
    ak.name, t.title, comp_kind
ORDER BY 
    t.production_year DESC, ak.name;
