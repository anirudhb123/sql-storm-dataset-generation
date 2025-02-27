SELECT 
    t.title,
    ak.name AS aka_name,
    p.name AS person_name,
    c.kind AS company_type,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    aka_title ak ON t.id = ak.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    keyword k ON t.id = k.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
