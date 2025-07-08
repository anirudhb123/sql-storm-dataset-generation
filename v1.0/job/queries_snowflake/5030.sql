SELECT 
    a.name AS actor_name, 
    m.title AS movie_title, 
    m.production_year, 
    c.role_id, 
    p.info AS actor_info, 
    COALESCE(cmp.name, 'N/A') AS company_name, 
    k.keyword AS keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_name cmp ON mc.company_id = cmp.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    m.production_year > 2000 AND 
    c.nr_order < 5 AND 
    k.keyword LIKE '%action%' 
ORDER BY 
    m.production_year DESC, 
    a.name;
