
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS cast_type,
    STRING_AGG(DISTINCT kw.keyword, ',') AS keywords,
    cp.name AS company_name,
    cp.country_code AS company_country
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cp ON mc.company_id = cp.id
WHERE 
    t.production_year >= 2000 
    AND c.kind = 'actor'
GROUP BY 
    a.name, t.title, t.production_year, c.kind, cp.name, cp.country_code
ORDER BY 
    t.production_year DESC, a.name;
