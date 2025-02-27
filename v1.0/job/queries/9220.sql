
SELECT 
    an.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    cct.kind AS cast_type,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    pi.info AS person_info
FROM 
    aka_name an
JOIN 
    cast_info ci ON an.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
JOIN 
    complete_cast cc ON at.id = cc.movie_id
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
JOIN 
    comp_cast_type cct ON ci.person_role_id = cct.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    person_info pi ON an.person_id = pi.person_id
WHERE 
    at.production_year > 2000
    AND cct.kind IS NOT NULL
GROUP BY 
    an.name, at.title, at.production_year, cct.kind, pi.info
ORDER BY 
    at.production_year DESC, an.name;
