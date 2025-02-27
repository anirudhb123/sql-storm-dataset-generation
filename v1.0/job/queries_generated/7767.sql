SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_role,
    m.company_name AS production_company,
    mu.info AS audience_rating,
    k.keyword AS genre
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    title mu ON t.id = mu.id
WHERE 
    m.country_code = 'USA'
    AND t.production_year > 2000
    AND it.info = 'rating'
    AND k.keyword IN ('Action', 'Drama', 'Comedy')
ORDER BY 
    t.production_year DESC, a.name;
