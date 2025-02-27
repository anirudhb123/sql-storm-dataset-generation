SELECT 
    t.title,
    a.name AS actor_name,
    c.note AS cast_note,
    m.name AS company_name,
    k.keyword
FROM 
    title AS t
JOIN 
    cast_info AS c ON t.id = c.movie_id
JOIN 
    aka_name AS a ON c.person_id = a.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS m ON mc.company_id = m.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
