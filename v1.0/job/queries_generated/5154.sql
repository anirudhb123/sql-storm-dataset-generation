SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS actor_name,
    r.role AS actor_role,
    c.note AS casting_note,
    tick.production_year AS release_year,
    COUNT(k.keyword) AS keyword_count
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_keyword mw ON t.id = mw.movie_id
JOIN 
    keyword k ON mw.keyword_id = k.id
JOIN 
    movie_info info ON t.id = info.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND t.production_year BETWEEN 2000 AND 2023 
    AND co.country_code = 'USA'
GROUP BY 
    ak.name, t.title, p.name, r.role, c.note, t.production_year
ORDER BY 
    release_year DESC, keyword_count DESC
LIMIT 50;
