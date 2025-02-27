SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS role_name,
    c.kind AS company_kind,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT ci.id) AS total_cast,
    COUNT(DISTINCT ci2.id) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
    AND cn.country_code = 'USA'
    AND k.keyword IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, r.role, c.kind, k.keyword
ORDER BY 
    total_cast DESC, t.production_year DESC, actor_name ASC
LIMIT 50;
