SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    r.role AS person_role, 
    p.info AS person_info, 
    k.keyword AS movie_keyword, 
    cmt.kind AS company_type 
FROM 
    aka_name AS a 
JOIN 
    cast_info AS c ON a.person_id = c.person_id 
JOIN 
    title AS t ON c.movie_id = t.id 
JOIN 
    role_type AS r ON c.role_id = r.id 
JOIN 
    person_info AS p ON a.person_id = p.person_id 
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id 
JOIN 
    keyword AS k ON mk.keyword_id = k.id 
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id 
JOIN 
    company_type AS cmt ON mc.company_type_id = cmt.id 
WHERE 
    t.production_year BETWEEN 1990 AND 2000 
    AND k.keyword LIKE '%action%' 
    AND p.info_type_id = 1 
ORDER BY 
    t.production_year DESC, 
    a.name, 
    c.nr_order;
