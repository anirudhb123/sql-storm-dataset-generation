SELECT 
    t.title,
    ak.name AS aka_name,
    c.name AS cast_name,
    ct.kind AS company_type,
    keyword.keyword AS movie_keyword,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    aka_title ak ON t.id = ak.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    name c ON ci.person_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ON mk.keyword_id = keyword.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    ak.name;
