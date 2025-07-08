SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS role_order, 
    g.kind AS genre, 
    comp.name AS production_company, 
    k.keyword AS keyword 
FROM 
    aka_name AS a 
JOIN 
    cast_info AS c ON a.person_id = c.person_id 
JOIN 
    aka_title AS t ON c.movie_id = t.movie_id 
JOIN 
    kind_type AS g ON t.kind_id = g.id 
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id 
JOIN 
    company_name AS comp ON mc.company_id = comp.id 
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id 
JOIN 
    keyword AS k ON mk.keyword_id = k.id 
WHERE 
    t.production_year >= 2000 AND 
    g.kind IN ('Drama', 'Comedy') 
ORDER BY 
    a.name, t.production_year DESC, c.nr_order;
