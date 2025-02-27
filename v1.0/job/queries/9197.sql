
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS cast_type,
    STRING_AGG(k.keyword, ', ') AS keywords,
    STRING_AGG(p.info, ', ') AS person_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    comp_cast_type AS c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info AS p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000
    AND c.kind = 'actor'
GROUP BY 
    a.name, t.title, t.production_year, c.kind
ORDER BY 
    t.production_year DESC, a.name ASC;
