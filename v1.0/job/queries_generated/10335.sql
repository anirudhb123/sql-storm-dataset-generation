-- Performance Benchmarking SQL Query
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS role,
    c.production_year AS release_year,
    GROUP_CONCAT(k.keyword) AS keywords
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    c.production_year >= 2000
    AND t.kind_id = 1 -- assuming kind_id 1 is for feature films
GROUP BY 
    t.title, a.name, r.role, c.production_year
ORDER BY 
    c.production_year DESC;
