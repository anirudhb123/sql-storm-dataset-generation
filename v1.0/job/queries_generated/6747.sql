SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    m.production_year,
    GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind) AS company_types,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    COUNT(DISTINCT tc.id) AS total_cast_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    info_type it ON pi.info_type_id = it.id
LEFT JOIN 
    title tc ON tc.episode_of_id = t.id
WHERE 
    m.production_year >= 2000
GROUP BY 
    a.name, t.title, m.production_year
ORDER BY 
    m.production_year DESC, actor_name ASC;
