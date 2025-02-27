SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    cjr.kind AS company_role,
    COUNT(DISTINCT mi.movie_id) AS movie_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MAX(t.production_year) AS latest_movie_year
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
    comp_cast_type cjr ON mc.company_type_id = cjr.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name IS NOT NULL AND
    t.production_year > 2000
GROUP BY 
    a.name, t.title, cjr.kind
ORDER BY 
    movie_count DESC, latest_movie_year DESC;
