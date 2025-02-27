SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS role_kind,
    ci.note AS cast_note, 
    ci.nr_order AS cast_order,
    cc.name AS company_name,
    ki.keyword AS movie_keyword,
    COUNT(DISTINCT m.id) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    kind_type k ON t.kind_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cc ON mc.company_id = cc.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    complete_cast cc2 ON t.id = cc2.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND a.name IS NOT NULL 
    AND k.kind != 'documentary'
GROUP BY 
    actor_name, movie_title, role_kind, cast_note, cast_order, company_name, movie_keyword
ORDER BY 
    total_movies DESC, actor_name, movie_title;
