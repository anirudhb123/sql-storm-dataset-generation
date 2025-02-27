SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    m.production_year,
    GROUP_CONCAT(k.keyword) AS keywords,
    c.kind AS company_type,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_info m ON t.movie_id = m.movie_id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Awards')
    AND m.info LIKE '%Oscar%'
    AND t.production_year > 2000
GROUP BY 
    a.name, t.title, m.production_year, c.kind, p.info
ORDER BY 
    m.production_year DESC, actor_name;
