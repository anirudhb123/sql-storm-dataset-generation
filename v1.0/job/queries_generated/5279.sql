SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    y.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT c.name) AS company_names,
    COUNT(DISTINCT m.id) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mw ON t.id = mw.movie_id
JOIN 
    keyword k ON mw.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_title at ON t.id = at.movie_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
    AND it.info LIKE '%box office%'
GROUP BY 
    a.name, t.title, y.production_year
HAVING 
    COUNT(DISTINCT k.id) > 1
ORDER BY 
    total_movies DESC, y.production_year DESC
LIMIT 100;
