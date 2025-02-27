
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords, 
    c.kind AS comp_kind, 
    co.name AS company_name 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name co ON mc.company_id = co.id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id 
WHERE 
    t.production_year > 2000 
    AND co.country_code = 'USA' 
GROUP BY 
    a.name, t.title, t.production_year, c.kind, co.name 
ORDER BY 
    t.production_year DESC;
