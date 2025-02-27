SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.nr_order AS actor_order,
    cc.kind AS comp_cast_type,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    ti.info AS movie_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info c ON at.movie_id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    comp_cast_type cc ON c.person_role_id = cc.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
ORDER BY 
    t.title, actor_order;
