SELECT 
    t.title AS movie_title,
    t.production_year,
    a.name AS actor_name,
    GROUP_CONCAT(k.keyword) AS keywords,
    COUNT(DISTINCT c.person_id) AS total_cast_members,
    cp.kind AS company_type,
    GROUP_CONCAT(DISTINCT i.info) AS additional_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type cp ON mc.company_type_id = cp.id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type i_t ON mi.info_type_id = i_t.id
LEFT JOIN 
    movie_info_idx mi_idx ON t.id = mi_idx.movie_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
    AND cn.country_code = 'USA'
    AND a.name IS NOT NULL
GROUP BY 
    t.id, a.name, cp.kind
ORDER BY 
    t.production_year DESC, total_cast_members DESC;
