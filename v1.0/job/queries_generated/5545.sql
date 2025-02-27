SELECT 
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS role_type,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
    c.name AS company_name,
    ci.note AS cast_info_note
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    t.production_year > 2000 
    AND ci.nr_order < 5 
GROUP BY 
    t.id, p.id, r.id, c.id
ORDER BY 
    t.title, p.name;
