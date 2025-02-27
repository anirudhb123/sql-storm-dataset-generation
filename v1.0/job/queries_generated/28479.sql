SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.kind AS role_type,
    k.keyword AS movie_keyword,
    ci.note AS cast_note,
    cc.name AS company_name,
    ti.info AS additional_info,
    t.production_year AS year_of_release,
    COUNT(DISTINCT m.id) AS total_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_associated
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_name cc ON mc.company_id = cc.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id
LEFT JOIN 
    info_type ti ON mi.info_type_id = ti.id
LEFT JOIN 
    title t ON m.id = t.id
WHERE 
    a.name IS NOT NULL
    AND m.production_year BETWEEN 2000 AND 2023
    AND cc.country_code = 'USA'
GROUP BY 
    a.name, m.title, c.kind, k.keyword, ci.note, cc.name, ti.info, t.production_year
ORDER BY 
    total_movies DESC, actor_name ASC;
