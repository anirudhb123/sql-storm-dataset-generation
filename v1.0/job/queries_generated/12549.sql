SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    COUNT(ci.id) AS cast_count, 
    GROUP_CONCAT(DISTINCT p.name) AS cast_members 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    aka_title t ON ci.movie_id = t.movie_id 
JOIN 
    title tt ON t.id = tt.id 
JOIN 
    person_info pi ON a.person_id = pi.person_id 
GROUP BY 
    a.name, t.title 
ORDER BY 
    cast_count DESC, movie_title;
