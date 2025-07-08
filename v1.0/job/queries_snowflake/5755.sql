SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role,
    k.keyword AS keyword,
    co.name AS company_name,
    COUNT(*) AS appearances,
    SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS awards_count
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND k.keyword IN ('Action', 'Drama')
    AND c.kind = 'actor'
GROUP BY 
    t.title, a.name, c.kind, k.keyword, co.name
ORDER BY 
    appearances DESC, awards_count DESC
LIMIT 10;
