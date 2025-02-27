SELECT 
    ak.name AS aka_name,
    at.title AS movie_title,
    ci.nr_order AS cast_order,
    pn.name AS person_name,
    co.name AS company_name,
    mt.kind AS company_type,
    mi.info AS movie_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title at ON ci.movie_id = at.id
JOIN 
    company_name co ON ci.movie_id = movie_companies.movie_id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    movie_info mi ON at.id = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
ORDER BY 
    at.production_year DESC, ci.nr_order;
