
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    STRING_AGG(DISTINCT t.title, ', ') AS movies_list,
    COALESCE(AVG(CAST(m_info.info AS numeric)), 0) AS average_rating,
    ARRAY_AGG(DISTINCT k.keyword) AS movie_keywords
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_info m_info ON t.id = m_info.movie_id AND m_info.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ak.name IS NOT NULL
    AND t.production_year >= 2000
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    total_movies DESC
LIMIT 10;
