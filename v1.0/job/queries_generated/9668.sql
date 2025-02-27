SELECT 
    a.id AS aka_name_id, 
    a.name AS aka_name, 
    a.imdb_index AS aka_imdb_index, 
    t.title AS movie_title, 
    t.production_year, 
    c.nr_order AS cast_order, 
    cn.name AS company_name, 
    ct.kind AS company_type, 
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
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
WHERE 
    a.name_pcode_nf IS NOT NULL 
    AND t.production_year > 2000 
    AND ct.kind LIKE 'Distributor%'
ORDER BY 
    t.production_year DESC, 
    a.name;
