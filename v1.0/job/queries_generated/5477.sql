SELECT 
    a.name AS actor_name,
    b.title AS movie_title,
    c.kind AS company_type,
    d.info AS movie_info,
    e.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info f ON a.person_id = f.person_id
JOIN 
    aka_title b ON f.movie_id = b.movie_id
JOIN 
    movie_companies g ON b.id = g.movie_id
JOIN 
    company_type c ON g.company_type_id = c.id
JOIN 
    movie_info d ON b.id = d.movie_id
JOIN 
    movie_keyword h ON b.id = h.movie_id
JOIN 
    keyword e ON h.keyword_id = e.id
WHERE 
    b.production_year >= 2000 
    AND d.info_type_id IN (SELECT id FROM info_type WHERE info = 'Awards')
ORDER BY 
    a.name, b.production_year DESC;
