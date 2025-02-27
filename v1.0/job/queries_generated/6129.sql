SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    ci.note AS cast_note,
    m.info AS movie_information,
    k.keyword AS movie_keyword,
    COUNT(mc.id) AS company_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type c ON ci.role_id = c.id
WHERE 
    t.production_year > 2000 
    AND ci.nr_order < 5 
    AND k.keyword ILIKE '%action%'
GROUP BY 
    a.name, t.title, c.kind, ci.note, m.info, k.keyword
ORDER BY 
    company_count DESC, actor_name ASC;
