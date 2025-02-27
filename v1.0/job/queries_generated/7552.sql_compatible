
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    STRING_AGG(DISTINCT k.keyword, ',') AS keywords, 
    yt.info AS year_info,
    COUNT(DISTINCT m.company_id) AS production_companies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type yt ON mi.info_type_id = yt.id
JOIN 
    movie_companies m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000 AND
    yt.info = 'Release Year'
GROUP BY 
    a.name, t.title, c.kind, yt.info
ORDER BY 
    COUNT(DISTINCT m.company_id) DESC, 
    a.name ASC;
