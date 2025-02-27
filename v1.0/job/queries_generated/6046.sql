SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    c.nr_order AS actor_order,
    m.production_year,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    title m ON t.movie_id = m.id
WHERE 
    m.production_year >= 2000 
    AND m.kind_id IN (1, 2) 
GROUP BY 
    a.name, t.title, c.kind, c.nr_order, m.production_year 
ORDER BY 
    m.production_year DESC, actor_name ASC;
