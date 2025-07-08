
SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    r.role AS actor_role,
    c.name AS company_name,
    mi.info AS movie_info,
    k.keyword AS movie_keyword,
    COUNT(*) AS appearances
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000
    AND c.country_code = 'USA'
GROUP BY 
    t.title, ak.name, r.role, c.name, mi.info, k.keyword
ORDER BY 
    appearances DESC
LIMIT 10;
