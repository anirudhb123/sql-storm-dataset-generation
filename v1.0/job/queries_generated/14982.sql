SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    cnty.name AS company_name,
    cnty.country_code AS company_country,
    m.production_year
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cnty ON mc.company_id = cnty.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year, t.title;
