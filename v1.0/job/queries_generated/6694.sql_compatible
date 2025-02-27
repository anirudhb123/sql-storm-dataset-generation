
SELECT 
    at.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS cast_type,
    c.name AS company_name,
    STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
    COUNT(DISTINCT m.id) AS total_movies,
    MAX(m.production_year) AS latest_movie_year
FROM 
    aka_title AS at
JOIN 
    cast_info AS ci ON at.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_companies AS mc ON at.id = mc.movie_id
JOIN 
    company_name AS c ON mc.company_id = c.id
JOIN 
    comp_cast_type AS ct ON ci.person_role_id = ct.id
LEFT JOIN 
    movie_keyword AS mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    title AS m ON at.id = m.id
WHERE 
    m.production_year BETWEEN 2000 AND 2020
GROUP BY 
    at.title, a.name, ct.kind, c.name, m.production_year
ORDER BY 
    total_movies DESC, latest_movie_year DESC
LIMIT 10;
