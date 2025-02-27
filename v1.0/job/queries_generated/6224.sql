SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS cast_type,
    k.keyword AS movie_keyword,
    GROUP_CONCAT(DISTINCT cn.name_ordered SEPARATOR ', ') AS companies_involved,
    GROUP_CONCAT(DISTINCT p.info SEPARATOR '; ') AS actor_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
GROUP BY 
    a.id, t.id, c.kind, k.id
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 2
ORDER BY 
    t.production_year DESC, a.name;
