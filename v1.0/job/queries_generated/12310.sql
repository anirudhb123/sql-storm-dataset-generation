SELECT 
    t.title, 
    a.name AS actor_name, 
    c.nr_order, 
    k.keyword, 
    cn.name AS company_name, 
    ct.kind AS company_type
FROM 
    title AS t
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    company_type AS ct ON mc.company_type_id = ct.id
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
ORDER BY 
    t.title, 
    a.name;
