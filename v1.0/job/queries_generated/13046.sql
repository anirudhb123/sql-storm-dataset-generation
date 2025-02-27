SELECT 
    t.title AS movie_title,
    ak.name AS aka_name,
    c.name AS character_name,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    ct.kind AS company_type,
    i.info AS movie_info
FROM 
    title t
JOIN 
    aka_title ak ON t.id = ak.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    name n ON ci.person_id = n.id
JOIN 
    char_name c ON n.id = c.imdb_id
JOIN 
    person_info p ON n.id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    t.production_year >= 2000
AND 
    ct.kind = 'Distributor'
ORDER BY 
    t.production_year DESC, t.title;
