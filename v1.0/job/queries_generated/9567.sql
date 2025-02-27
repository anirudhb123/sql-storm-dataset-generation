SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    g.kind AS genre,
    m.info AS company_info,
    k.keyword AS movie_keyword,
    GROUP_CONCAT(DISTINCT w.linked_movie_id) AS related_movies
FROM 
    title t
JOIN 
    aka_title ak_t ON t.id = ak_t.movie_id
JOIN 
    aka_name ak ON ak_t.id = ak.id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    keyword k ON t.id = k.movie_id
LEFT JOIN 
    movie_link w ON t.id = w.movie_id
WHERE 
    t.production_year >= 2000 
    AND ak.name IS NOT NULL 
    AND r.role = 'actor'
GROUP BY 
    t.title, ak.name, g.kind, m.info, k.keyword
ORDER BY 
    t.production_year DESC, ak.name ASC;
