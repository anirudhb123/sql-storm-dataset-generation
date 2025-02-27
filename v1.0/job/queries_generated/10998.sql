SELECT 
    p.name AS person_name,
    m.title AS movie_title,
    c.note AS cast_note,
    ct.kind AS character_type,
    COALESCE(k.keyword, 'N/A') AS keyword,
    ci.kind AS company_type
FROM 
    aka_name AS p
JOIN 
    cast_info AS c ON p.person_id = c.person_id
JOIN 
    title AS m ON c.movie_id = m.id
LEFT JOIN 
    movie_keyword AS mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies AS mc ON m.id = mc.movie_id
LEFT JOIN 
    company_type AS ct ON mc.company_type_id = ct.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, p.name;
