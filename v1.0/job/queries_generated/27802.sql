SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    MIN(m.production_year) AS earliest_movie_year,
    AVG(m.production_year) AS average_movie_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_used 
FROM 
    aka_title t 
JOIN 
    cast_info ci ON t.id = ci.movie_id 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
JOIN 
    role_type c ON ci.role_id = c.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_info m_info ON t.id = m_info.movie_id 
JOIN 
    movie_info m ON m_info.movie_id = m.movie_id 
WHERE 
    t.production_year >= 2000 
    AND t.title IS NOT NULL 
    AND a.name IS NOT NULL
GROUP BY 
    t.title, a.name, c.kind 
ORDER BY 
    keyword_count DESC, average_movie_year DESC;
