SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT c.role_id) AS roles,
    GROUP_CONCAT(DISTINCT g.kind) AS genres,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT l.linked_movie_id) AS linked_movies_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_link l ON t.id = l.movie_id
LEFT JOIN 
    kind_type g ON t.kind_id = g.id
WHERE 
    a.name LIKE '%Smith%'
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, t.production_year
ORDER BY 
    t.production_year DESC, a.name ASC;

This query benchmarks various string processing capabilities by retrieving detailed information about actors named 'Smith', their movie titles, production years, roles, associated genres, keywords, and linked movies produced within a specified year range. It utilizes multiple joins, aggregation functions, and string pattern matching to demonstrate the complexities of string processing in SQL.
