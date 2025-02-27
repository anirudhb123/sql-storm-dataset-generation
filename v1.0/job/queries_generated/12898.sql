SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_kind,
    COALESCE(k.keyword, 'No Keyword') AS keyword,
    mp.name AS production_company,
    mt.info AS movie_info
FROM 
    title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    role_type AS c ON ci.role_id = c.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name AS mp ON mc.company_id = mp.id
LEFT JOIN 
    movie_info AS mt ON t.id = mt.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
