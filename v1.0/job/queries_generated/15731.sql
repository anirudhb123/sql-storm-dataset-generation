SELECT DISTINCT
    t.title, 
    a.name, 
    c.note, 
    m.info
FROM 
    title AS t
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    cast_info AS c ON t.id = c.movie_id
JOIN 
    aka_name AS a ON c.person_id = a.person_id
JOIN 
    movie_info AS m ON t.id = m.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.title;
