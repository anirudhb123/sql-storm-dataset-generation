
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    ct.kind AS company_type, 
    t.production_year AS release_year, 
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
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
    company_type ct ON mc.company_type_id = ct.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
    AND t.production_year BETWEEN 2000 AND 2023 
    AND ct.kind LIKE '%Production%'
GROUP BY 
    a.name, t.title, ct.kind, t.production_year 
ORDER BY 
    release_year DESC, actor_name;
