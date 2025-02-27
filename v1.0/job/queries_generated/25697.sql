SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    GROUP_CONCAT(DISTINCT k.keyword) AS movie_keywords,
    p.info AS person_info,
    nt.kind AS role_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    role_type nt ON c.person_role_id = nt.id
WHERE 
    t.production_year > 2000
    AND a.name IS NOT NULL
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
GROUP BY 
    a.name, t.title, c.note, p.info, nt.kind
ORDER BY 
    movie_title ASC, aka_name ASC;
