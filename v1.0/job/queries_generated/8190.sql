SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    c.nr_order AS role_order,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    ci.name AS company_name,
    ti.info AS movie_info
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = c.movie_id
JOIN 
    company_name ci ON mc.company_id = ci.id
JOIN 
    movie_keyword mk ON mk.movie_id = c.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON mi.movie_id = c.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
    AND ci.country_code = 'USA'
GROUP BY 
    a.name, t.title, c.kind, c.nr_order, ci.name, ti.info
ORDER BY 
    t.production_year DESC, c.nr_order ASC
LIMIT 100;
