SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_kind,
    COUNT(mc.company_id) AS company_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COALESCE(SUM(mii.info::integer), 0) AS total_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_info_idx mii ON mi.id = mii.movie_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    total_info DESC, actor_name ASC;
