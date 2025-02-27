SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    co.name AS company_name,
    co.country_code,
    m.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT ci.person_id) AS cast_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
    AND t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
GROUP BY 
    a.id, t.id, co.id, c.id
ORDER BY 
    m.production_year DESC;
