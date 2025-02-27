SELECT 
    a.id AS aka_id,
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT p.id) AS distinct_person_info_count,
    AVG(p.info_length) AS average_info_length
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    (SELECT 
         person_id, 
         LENGTH(info) AS info_length 
     FROM 
         person_info) p ON a.person_id = p.person_id
WHERE 
    t.production_year > 2000
GROUP BY 
    a.id, a.name, t.title, t.production_year, c.kind, k.keyword
HAVING 
    COUNT(DISTINCT p.id) > 5
ORDER BY 
    t.production_year DESC, actor_name ASC;
