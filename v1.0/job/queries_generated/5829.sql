SELECT 
    t.title AS movie_title, 
    ak.name AS actor_name, 
    c.kind AS cast_type, 
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords, 
    GROUP_CONCAT(DISTINCT cn.name) AS companies
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.id, ak.name, c.kind
HAVING 
    COUNT(DISTINCT ci.person_id) > 1
ORDER BY 
    t.production_year DESC, movie_title;
