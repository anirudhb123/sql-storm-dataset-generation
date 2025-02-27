SELECT 
    at.title AS movie_title,
    a.name AS actor_name,
    ARRAY_AGG(DISTINCT k.keyword) AS movie_keywords,
    c.kind AS company_type,
    GROUP_CONCAT(DISTINCT p.info ORDER BY p.info_type_id) AS person_information
FROM 
    aka_title at
JOIN 
    cast_info ci ON at.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON at.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    at.production_year >= 2000 AND 
    ct.kind = 'Production' AND 
    k.keyword LIKE '%action%'
GROUP BY 
    at.id, a.id, cn.name, ct.kind
ORDER BY 
    at.title, a.name;
