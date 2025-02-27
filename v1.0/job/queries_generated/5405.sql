SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS role,
    cc.id AS complete_cast_id,
    COALESCE(MAX(ci.note), 'No Note Available') AS cast_note,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, c.role_id, cc.id
ORDER BY 
    actor_name, movie_title;
