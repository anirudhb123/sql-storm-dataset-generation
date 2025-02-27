SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    y.production_year,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    cast_info ci
JOIN 
    aka_name n ON ci.person_id = n.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    movie_keyword mw ON t.id = mw.movie_id
JOIN 
    keyword kw ON mw.keyword_id = kw.id
JOIN 
    title y ON t.movie_id = y.id
WHERE 
    y.production_year > 2000
AND 
    ci.nr_order < 5
AND 
    mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')
GROUP BY 
    n.name, t.title, y.production_year
ORDER BY 
    y.production_year DESC, actor_name ASC;
