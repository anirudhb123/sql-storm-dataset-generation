SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT cn.name) AS company_names,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    pi.info AS person_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON a.id = pi.person_id
WHERE 
    t.production_year >= 2000
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
GROUP BY 
    a.id, t.id, pi.info
ORDER BY 
    t.production_year DESC, a.name;
