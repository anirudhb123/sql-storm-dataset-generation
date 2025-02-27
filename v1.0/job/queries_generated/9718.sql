SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    m.production_year, 
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords
FROM 
    cast_info ci 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
JOIN 
    aka_title t ON ci.movie_id = t.movie_id 
JOIN 
    role_type r ON ci.role_id = r.id 
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id 
JOIN 
    movie_info mi ON cc.movie_id = mi.movie_id 
JOIN 
    movie_keyword mk ON mk.movie_id = mi.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_companies mc ON mc.movie_id = t.id 
JOIN 
    company_name co ON mc.company_id = co.id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
WHERE 
    t.production_year >= 2000 
    AND a.name IS NOT NULL 
    AND k.keyword IS NOT NULL 
GROUP BY 
    actor_name, movie_title, cast_type, m.production_year 
ORDER BY 
    m.production_year DESC, actor_name;
