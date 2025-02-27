SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id,
    ci.note AS cast_note,
    m.production_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names,
    STRING_AGG(DISTINCT pi.info, '; ') AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    info_type it ON pi.info_type_id = it.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND a.name LIKE '%Smith%'
GROUP BY 
    a.id, t.id, ci.role_id, ci.note, m.production_year
ORDER BY 
    actor_name ASC,
    movie_title ASC;
