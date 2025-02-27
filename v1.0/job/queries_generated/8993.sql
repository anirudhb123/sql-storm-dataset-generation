SELECT 
    n.name AS Actor_Name,
    t.title AS Movie_Title,
    c.kind AS Company_Type,
    COUNT(DISTINCT mc.movie_id) AS Total_Movies,
    AVG(yi.year_of_release) AS Average_Release_Year
FROM 
    aka_name n
JOIN 
    cast_info ci ON n.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    (SELECT 
        movie_id, 
        EXTRACT(YEAR FROM production_year) AS year_of_release 
     FROM 
        aka_title 
     WHERE 
        production_year IS NOT NULL) yi ON t.id = yi.movie_id
WHERE 
    n.name IS NOT NULL
GROUP BY 
    n.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5
ORDER BY 
    Total_Movies DESC, 
    Average_Release_Year ASC
LIMIT 10;
