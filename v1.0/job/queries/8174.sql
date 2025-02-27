
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    STRING_AGG(DISTINCT k.keyword, ', ' ORDER BY k.keyword) AS keywords, 
    STRING_AGG(DISTINCT c.kind, ', ' ORDER BY c.kind) AS comp_types 
FROM 
    aka_name AS a 
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id 
JOIN 
    title AS t ON ci.movie_id = t.id 
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id 
JOIN 
    keyword AS k ON mk.keyword_id = k.id 
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id 
JOIN 
    company_type AS c ON mc.company_type_id = c.id 
WHERE 
    t.production_year >= 2000 
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('feature', 'short')) 
GROUP BY 
    a.name, t.title, t.production_year 
ORDER BY 
    t.production_year DESC, a.name;
