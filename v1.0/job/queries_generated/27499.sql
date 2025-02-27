SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keyword_list,
    ci.note AS role_note,
    ct.kind AS company_type,
    c.name AS company_name,
    m.production_year
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
    AND a.name IS NOT NULL
    AND k.keyword IS NOT NULL
GROUP BY 
    t.id, a.name, ci.note, c.name, ct.kind, m.production_year
ORDER BY 
    t.production_year DESC, keyword_count DESC;
