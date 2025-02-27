SELECT 
    t.title, 
    ak.name AS aka_name, 
    ci.note AS cast_note, 
    cst.kind AS company_type, 
    mi.info AS movie_info, 
    k.keyword 
FROM 
    title t
JOIN 
    aka_title ak ON t.id = ak.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type cst ON mc.company_type_id = cst.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
