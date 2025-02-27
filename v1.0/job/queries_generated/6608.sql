SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS comp_cast_type,
    k.keyword AS movie_keyword,
    ci.info AS company_info,
    ti.info AS title_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    aka_title AS t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    comp_cast_type AS c ON ci.person_role_id = c.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
JOIN 
    info_type AS ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year > 2000
    AND k.keyword LIKE '%action%'
ORDER BY 
    a.name, t.production_year DESC;
