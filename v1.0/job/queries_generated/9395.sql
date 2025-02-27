SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    m.production_year,
    kw.keyword AS movie_keyword,
    p.info AS person_info,
    cnt.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cnt ON mc.company_id = cnt.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'box office')
    AND t.production_year >= 2000
    AND a.name IS NOT NULL
ORDER BY 
    m.production_year DESC, a.name;
