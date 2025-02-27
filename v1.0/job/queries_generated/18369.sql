SELECT 
    a.name AS Actor_Name, 
    t.title AS Movie_Title, 
    t.production_year AS Production_Year 
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    aka_title AS t ON ci.movie_id = t.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
