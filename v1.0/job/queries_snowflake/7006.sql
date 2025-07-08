
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    LISTAGG(DISTINCT k.keyword, ',') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    COUNT(DISTINCT ci.person_id) AS cast_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT k.keyword) > 3
ORDER BY 
    cast_count DESC, movie_title ASC;
