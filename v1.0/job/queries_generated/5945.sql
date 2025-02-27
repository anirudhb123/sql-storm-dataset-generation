SELECT 
    p.name AS person_name,
    t.title AS movie_title,
    c.kind AS company_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    i.info AS movie_info,
    a.name AS aka_name
FROM 
    person_info pi
JOIN 
    aka_name a ON pi.person_id = a.person_id
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    c.kind LIKE 'Production%'
GROUP BY 
    p.name, t.title, c.kind, i.info, a.name
ORDER BY 
    person_name, movie_title;
