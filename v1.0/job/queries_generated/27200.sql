SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
    COUNT(DISTINCT ci.person_id) AS total_cast_members,
    MIN(t.production_year) AS first_movie_year,
    MAX(t.production_year) AS last_movie_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
    AND t.title IS NOT NULL
    AND c.kind IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT k.keyword) > 0
ORDER BY 
    total_cast_members DESC, first_movie_year ASC;
