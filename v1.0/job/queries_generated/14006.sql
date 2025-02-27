SELECT 
    p.name AS actor_name,
    m.title AS movie_title,
    c.nr_order AS cast_order,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    it.info AS movie_info
FROM 
    aka_name p
JOIN 
    cast_info c ON p.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON m.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, p.name;
