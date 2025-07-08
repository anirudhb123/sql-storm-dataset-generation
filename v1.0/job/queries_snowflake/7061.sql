SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    pi.info AS person_info,
    c1.note AS cast_note
FROM 
    aka_name AS a
JOIN 
    cast_info AS c1 ON a.person_id = c1.person_id
JOIN 
    title AS t ON c1.movie_id = t.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS c ON mc.company_type_id = c.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    person_info AS pi ON a.person_id = pi.person_id
WHERE 
    t.production_year >= 2000 
    AND c.kind LIKE 'Production%' 
    AND a.name IS NOT NULL 
ORDER BY 
    t.production_year DESC, a.name;
