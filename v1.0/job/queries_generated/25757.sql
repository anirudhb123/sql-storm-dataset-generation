SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    k.keyword AS movie_keyword,
    ci.name AS company_name,
    mi.info AS movie_info,
    COUNT(*) OVER (PARTITION BY a.id) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    role_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name ILIKE '%Robert%'   -- Filtering for actors with 'Robert' in their name
    AND t.production_year >= 2000  -- Considering movies produced since 2000
    AND ci.nr_order = 1  -- Focusing on main cast
ORDER BY 
    total_movies DESC, 
    t.production_year DESC
LIMIT 10;
