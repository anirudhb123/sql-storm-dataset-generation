SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS number_of_companies,
    GROUP_CONCAT(DISTINCT ki.keyword) AS keywords,
    AVG(mi.info) AS average_length_of_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND a.name IS NOT NULL
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%%')
GROUP BY 
    t.id, a.id, ct.kind
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    average_length_of_info DESC, movie_title ASC;
