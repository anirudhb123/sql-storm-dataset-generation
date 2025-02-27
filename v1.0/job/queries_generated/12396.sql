SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    pt.kind AS production_company,
    kt.keyword AS keyword,
    ti.info AS additional_info
FROM 
    title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    company_type AS ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS kt ON mk.keyword_id = kt.id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
JOIN 
    info_type AS ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
