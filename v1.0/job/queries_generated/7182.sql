SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword ASC) AS keywords,
    c.kind AS cast_role,
    tc.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS number_of_companies,
    COUNT(DISTINCT ci.id) AS number_of_cast
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
    cast_info ci ON cc.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year >= 2000
    AND t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
GROUP BY 
    t.title, a.name, c.kind, ct.kind
ORDER BY 
    t.title ASC, a.name ASC;
