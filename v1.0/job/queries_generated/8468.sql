SELECT 
    t.title AS Movie_Title,
    a.name AS Actor_Name,
    c.role_id AS Role_ID,
    ci.kind AS Company_Type,
    COUNT(DISTINCT mk.keyword) AS Keyword_Count,
    MIN(m.production_year) AS First_Production_Year,
    MAX(m.production_year) AS Most_Recent_Production_Year
FROM 
    aka_title AS t
JOIN 
    movie_companies AS mc ON t.movie_id = mc.movie_id
JOIN 
    company_name AS c ON mc.company_id = c.id
JOIN 
    complete_cast AS cc ON t.movie_id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword AS mk ON t.movie_id = mk.movie_id
WHERE 
    c.country_code = 'USA'
AND 
    t.production_year BETWEEN 1990 AND 2020
GROUP BY 
    t.title, a.name, c.kind
ORDER BY 
    First_Production_Year DESC, Most_Recent_Production_Year ASC;
