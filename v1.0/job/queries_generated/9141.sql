SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    ci.kind AS character_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name) AS company_names,
    MAX(m.production_year) AS latest_movie_year,
    COUNT(DISTINCT m.id) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON t.id = c.movie_id
JOIN 
    kind_type kt ON kt.id = t.kind_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name cn ON cn.id = mc.company_id
JOIN 
    complete_cast cc ON cc.movie_id = t.id
JOIN 
    role_type rt ON rt.id = c.role_id
JOIN 
    movie_info m ON m.movie_id = t.id
WHERE 
    t.production_year > 2000 
    AND rt.role LIKE '%lead%'
GROUP BY 
    a.name, t.title, c.nr_order, ci.kind
HAVING 
    COUNT(DISTINCT k.id) > 5
ORDER BY 
    total_movies DESC, latest_movie_year DESC;
