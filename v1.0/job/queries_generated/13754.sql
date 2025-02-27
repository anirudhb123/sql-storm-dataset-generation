SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info,
    c.name AS company_name,
    k.keyword AS movie_keyword
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    person_info AS p ON a.person_id = p.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS c ON mc.company_id = c.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, t.title;
