SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    co.name AS company_name,
    ci.kind AS company_type,
    m.production_year,
    COUNT(DISTINCT m.id) AS total_movies,
    SUM(CASE WHEN kw.keyword IS NOT NULL THEN 1 ELSE 0 END) AS total_keywords
FROM 
    cast_info AS c
JOIN 
    aka_name AS a ON c.person_id = a.person_id
JOIN 
    aka_title AS t ON c.movie_id = t.movie_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS co ON mc.company_id = co.id
JOIN 
    company_type AS ci ON mc.company_type_id = ci.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
JOIN 
    title AS m ON t.id = m.id
WHERE 
    m.production_year > 2000
    AND co.country_code IN ('USA', 'GB', 'JP')
GROUP BY 
    a.name, t.title, co.name, ci.kind, m.production_year
ORDER BY 
    total_movies DESC, actor_name ASC;
