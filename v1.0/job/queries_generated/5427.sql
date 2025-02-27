SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_type,
    cc.note AS cast_note,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT co.name) AS company_names,
    i.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    t.production_year >= 2000
    AND i.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%rating%')
GROUP BY 
    a.name, t.title, c.kind, cc.note, i.info
ORDER BY 
    a.name, t.title;
