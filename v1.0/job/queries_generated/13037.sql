SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    pi.info AS person_info,
    c.kind AS comp_cast_type,
    cnt.name AS company_name,
    kw.keyword AS movie_keyword,
    r.role AS role_type,
    ti.title AS title_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    aka_title AS t ON ci.movie_id = t.movie_id
JOIN 
    person_info AS pi ON a.person_id = pi.person_id
JOIN 
    comp_cast_type AS c ON ci.role_id = c.id
JOIN 
    movie_companies AS mc ON ci.movie_id = mc.movie_id
JOIN 
    company_name AS cnt ON mc.company_id = cnt.id
JOIN 
    movie_keyword AS mk ON ci.movie_id = mk.movie_id
JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
JOIN 
    role_type AS r ON ci.person_role_id = r.id
JOIN 
    title AS ti ON ci.movie_id = ti.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
