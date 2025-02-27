SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS company_type,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mw ON t.id = mw.movie_id
JOIN 
    keyword k ON mw.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND a.name LIKE 'A%'
    AND k.keyword IN ('Action', 'Drama', 'Comedy')
ORDER BY 
    t.production_year DESC, 
    a.name;
