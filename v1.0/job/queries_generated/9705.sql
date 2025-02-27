SELECT 
    t.title AS movie_title,
    c.name AS actor_name,
    r.role AS role_name,
    m.name AS company_name,
    k.keyword AS keyword,
    CAST(MIN(co.id) AS INTEGER) AS company_id,
    COUNT(DISTINCT tc.id) AS total_cast,
    GROUP_CONCAT(DISTINCT ti.info, ', ') AS movie_info_details
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name c ON ci.person_id = c.person_id
JOIN 
    company_name m ON t.id = m.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_info_idx ti ON t.id = ti.movie_id
WHERE 
    t.production_year > 2000
    AND m.country_code = 'USA'
GROUP BY 
    t.title, c.name, r.role, m.name, k.keyword
ORDER BY 
    t.title, c.name;
