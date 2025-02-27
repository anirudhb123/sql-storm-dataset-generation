SELECT 
    akn.name AS aka_name,
    ttl.title AS movie_title,
    p.name AS person_name,
    ct.kind AS role_type,
    cmt.name AS company_name,
    kv.keyword AS movie_keyword,
    ti.info AS movie_info
FROM 
    aka_name akn
JOIN 
    cast_info ci ON akn.person_id = ci.person_id
JOIN 
    title ttl ON ci.movie_id = ttl.id
JOIN 
    role_type ct ON ci.role_id = ct.id
JOIN 
    movie_companies mc ON ttl.id = mc.movie_id
JOIN 
    company_name cmt ON mc.company_id = cmt.id
JOIN 
    movie_keyword mk ON ttl.id = mk.movie_id
JOIN 
    keyword kv ON mk.keyword_id = kv.id
JOIN 
    movie_info mi ON ttl.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    ttl.production_year > 2000
ORDER BY 
    ttl.production_year DESC;
