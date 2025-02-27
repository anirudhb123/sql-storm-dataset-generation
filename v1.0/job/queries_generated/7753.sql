SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    y.production_year,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT co.name) AS company_names
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON mk.movie_id = ci.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    movie_companies mc ON mc.movie_id = ci.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    title y ON t.movie_id = y.id
GROUP BY 
    a.name, t.title, c.kind, y.production_year
ORDER BY 
    y.production_year DESC, a.name ASC;
