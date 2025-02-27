SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    ci.note AS character_name, 
    ct.kind AS role_type,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names,
    COUNT(DISTINCT mc.id) AS num_companies,
    AVG(m.production_year) AS avg_production_year
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type ct ON ci.role_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (
        SELECT id FROM info_type WHERE info = 'summary'
    )
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND a.name IS NOT NULL
GROUP BY 
    t.title, a.name, ci.note, ct.kind
HAVING 
    COUNT(DISTINCT mc.id) > 1
ORDER BY 
    avg_production_year DESC, movie_title ASC;
