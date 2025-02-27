SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    c.nr_order AS role_order,
    mi.info AS movie_additional_info,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    t.production_year > 2000
    AND c.nr_order IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind, c.nr_order, mi.info
ORDER BY 
    a.name, t.title;
