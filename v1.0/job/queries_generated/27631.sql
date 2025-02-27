SELECT 
    t.title AS movie_title,
    t.production_year,
    a.name AS actor_name,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT c.kind) AS company_types,
    tp.role AS role_type
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
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
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    role_type tp ON ci.role_id = tp.id
WHERE 
    t.production_year BETWEEN 1990 AND 2023
    AND a.name ILIKE '%Smith%'
GROUP BY 
    t.title, t.production_year, a.name, tp.role
ORDER BY 
    t.production_year DESC, COUNT(k.keyword) DESC;

This SQL query benchmarks string processing by extracting movie titles featuring actors with "Smith" in their names over the span of years 1990 to 2023. It aggregates the keywords associated with those movies and categorizes the type of companies involved in the production, along with the roles played by the actors. The results are grouped and ordered to highlight the most recent productions with the highest keyword associations.
