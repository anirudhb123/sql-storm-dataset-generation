SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS role,
    tc.kind AS company_type,
    GROUP_CONCAT(k.keyword) AS keywords,
    MIN(m.production_year) AS first_movie_year,
    COUNT(DISTINCT m.id) AS movie_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title ta ON c.movie_id = ta.id
JOIN 
    title t ON ta.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    role_type rt ON c.role_id = rt.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
WHERE 
    a.name IS NOT NULL 
    AND ct.kind IS NOT NULL 
    AND t.production_year > 2000
GROUP BY 
    a.name, t.title, c.role_id, tc.kind
HAVING 
    COUNT(DISTINCT k.id) > 5
ORDER BY 
    actor_name, movie_title;
