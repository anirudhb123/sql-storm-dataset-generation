SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_role,
    cm.name AS company_name,
    k.keyword AS movie_keyword,
    mi.info AS movie_info,
    n.name AS person_name,
    p.info AS person_note
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cm ON mc.company_id = cm.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    name n ON a.person_id = n.imdb_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ci.nr_order < 5
    AND cm.country_code IN ('USA', 'UK')
ORDER BY 
    t.production_year DESC, 
    a.name;
