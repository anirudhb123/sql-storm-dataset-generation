SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind) AS company_types,
    t.production_year AS year_of_release,
    COUNT(DISTINCT ci.person_id) AS total_cast_members,
    COUNT(DISTINCT mi.info) AS total_movie_info
FROM 
    aka_title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_info AS mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
    AND k.keyword IS NOT NULL
GROUP BY 
    t.title, a.name, t.production_year
ORDER BY 
    total_cast_members DESC, t.production_year DESC
LIMIT 50;
