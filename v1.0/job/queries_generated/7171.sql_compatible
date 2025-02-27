
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ct.kind AS company_type,
    COUNT(DISTINCT k.keyword) AS total_keywords,
    MIN(ci.note) AS role_note,
    MAX(mi.info) AS movie_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000
GROUP BY 
    a.name, t.title, ct.kind
ORDER BY 
    total_keywords DESC, movie_title ASC;
