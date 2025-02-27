SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords, 
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names, 
    COUNT(DISTINCT p.id) AS total_persons
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info p ON c.person_id = p.person_id
WHERE 
    t.production_year >= 2000 
    AND a.name IS NOT NULL 
    AND cn.country_code = 'USA'
GROUP BY 
    a.id, t.id, c.kind
ORDER BY 
    total_persons DESC, movie_title ASC;
