SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    GROUP_CONCAT(DISTINCT kw.keyword SEPARATOR ', ') AS keywords,
    mi.info AS movie_info,
    COUNT(DISTINCT ci.id) AS cast_count
FROM 
    aka_name an
JOIN 
    cast_info ci ON an.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
JOIN 
    title t ON at.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    an.name IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    n.name, t.title, c.kind, mi.info
ORDER BY 
    cast_count DESC, actor_name ASC;
