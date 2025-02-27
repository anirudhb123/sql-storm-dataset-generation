SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    m.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    c.kind AS company_type,
    COUNT(DISTINCT ci.person_id) AS total_cast
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    it.info = 'Genre' AND
    t.production_year > 2000
GROUP BY 
    a.name, t.title, m.production_year, c.kind
ORDER BY 
    total_cast DESC, m.production_year DESC
LIMIT 50;
