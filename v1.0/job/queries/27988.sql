SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    COUNT(DISTINCT ci.id) AS cast_count,
    ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS recent_movie_rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL 
GROUP BY 
    a.id, t.id
ORDER BY 
    t.production_year DESC, actor_name;
