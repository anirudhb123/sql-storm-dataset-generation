SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    cc.kind AS company_type,
    pi.info AS person_info,
    COUNT(DISTINCT c.id) AS total_cast
FROM 
    aka_title t 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
JOIN 
    cast_info c ON t.id = c.movie_id 
JOIN 
    aka_name a ON c.person_id = a.person_id 
JOIN 
    person_info pi ON a.person_id = pi.person_id 
WHERE 
    t.production_year >= 2000 
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Release Notes') 
GROUP BY 
    t.title, a.name, cc.kind, pi.info 
HAVING 
    COUNT(DISTINCT k.id) > 1 
ORDER BY 
    total_cast DESC, movie_title ASC;
