SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    p.info AS person_info,
    MIN(m.production_year) AS earliest_movie_year,
    COUNT(DISTINCT m.id) AS total_movies,
    AVG(mi.info) AS average_rating
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    complete_cast cc ON cc.movie_id = t.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type ct ON ct.id = mc.company_type_id
JOIN 
    keyword k ON k.id = (SELECT movie_keyword.keyword_id FROM movie_keyword WHERE movie_keyword.movie_id = t.id LIMIT 1)
JOIN 
    person_info p ON p.person_id = a.person_id
JOIN 
    movie_info mi ON mi.movie_id = t.id
GROUP BY 
    t.title, a.name, c.kind, k.keyword, p.info
HAVING 
    COUNT(DISTINCT t.id) > 5
ORDER BY 
    earliest_movie_year DESC, total_movies DESC;
