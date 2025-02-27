SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.role_id,
    COUNT(ci.id) AS total_cast,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    c.note AS cast_note,
    mt.kind AS company_type,
    cn.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
WHERE 
    t.production_year >= 2000 
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
GROUP BY 
    a.name, t.title, t.production_year, c.role_id, c.note, mt.kind, cn.name
ORDER BY 
    t.production_year DESC, actor_name;
