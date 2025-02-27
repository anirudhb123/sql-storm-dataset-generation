
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT mi.id) AS movie_count,
    AVG(year_info.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    (SELECT movie_id, production_year FROM aka_title WHERE production_year IS NOT NULL) year_info ON t.id = year_info.movie_id
WHERE 
    c.kind IN ('Production', 'Distribution')
GROUP BY 
    a.name, t.title, c.kind, year_info.production_year
HAVING 
    COUNT(DISTINCT mi.id) > 5
ORDER BY 
    avg_production_year DESC, actor_name;
