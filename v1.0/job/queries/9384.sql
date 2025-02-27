
SELECT 
    ak.name AS actor_name,
    tt.title AS movie_title,
    tt.production_year,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_name,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT pt.info, ', ') AS person_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title tt ON ci.movie_id = tt.id
JOIN 
    movie_companies mc ON tt.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON tt.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    person_info pt ON ak.person_id = pt.person_id
WHERE 
    tt.production_year > 2000 
    AND ak.name IS NOT NULL
    AND cn.country_code = 'USA'
GROUP BY 
    ak.name, tt.title, tt.production_year
HAVING 
    COUNT(DISTINCT kw.id) > 2
ORDER BY 
    tt.production_year DESC, ak.name ASC;
