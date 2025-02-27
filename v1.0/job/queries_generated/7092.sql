SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id AS role_identifier, 
    tc.kind AS company_type, 
    COUNT(DISTINCT mc.company_id) AS company_count,
    MAX(m.production_year) AS latest_production_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    c.nr_order = 1
    AND t.production_year > 2000
    AND k.phonetic_code IS NOT NULL
GROUP BY 
    a.name, t.title, c.role_id, ct.kind
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    latest_production_year DESC, actor_name;
