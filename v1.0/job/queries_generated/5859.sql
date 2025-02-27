SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    co.name AS company_name,
    ti.info AS movie_info,
    kw.keyword AS movie_keyword
FROM 
    aka_name an
JOIN 
    cast_info ci ON an.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND co.country_code = 'USA'
    AND it.info LIKE '%box office%'
ORDER BY 
    t.production_year DESC, 
    actor_name;
