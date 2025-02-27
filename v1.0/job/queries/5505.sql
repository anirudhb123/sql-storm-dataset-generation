
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    ct.kind AS company_type, 
    mi.info AS movie_info, 
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND ct.kind = 'Distributor'
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
GROUP BY 
    a.name, t.title, ct.kind, mi.info, t.production_year
HAVING 
    COUNT(DISTINCT k.id) > 3
ORDER BY 
    t.production_year DESC, a.name;
