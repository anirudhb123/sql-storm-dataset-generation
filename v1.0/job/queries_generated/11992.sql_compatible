
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    t.production_year,
    k.keyword AS movie_keyword
FROM 
    title AS t
JOIN 
    aka_title AS at ON t.id = at.movie_id
JOIN 
    cast_info AS ci ON at.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type AS c ON ci.person_role_id = c.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, a.name, c.kind, t.production_year, k.keyword
ORDER BY 
    t.production_year DESC, 
    a.name;
