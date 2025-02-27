SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    mk.keyword AS movie_keyword, 
    tn.name AS title_name,
    COUNT(mk.id) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    title tn ON t.id = tn.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND mk.keyword LIKE '%action%'
GROUP BY 
    a.name, t.title, c.nr_order, mk.keyword, tn.name
ORDER BY 
    keyword_count DESC, actor_name ASC;
