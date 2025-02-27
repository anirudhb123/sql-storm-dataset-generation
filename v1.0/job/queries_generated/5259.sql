SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    comp.name AS company_name,
    m_info.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    aka_title t ON ci.movie_id = t.movie_id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id 
JOIN 
    company_name comp ON mc.company_id = comp.id 
JOIN 
    movie_info m_info ON cc.movie_id = m_info.movie_id 
JOIN 
    movie_keyword mk ON cc.movie_id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    t.production_year >= 2000 
    AND a.name IS NOT NULL 
    AND comp.country_code = 'USA' 
ORDER BY 
    t.production_year DESC, a.name;
