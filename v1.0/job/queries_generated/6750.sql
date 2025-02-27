SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    cc.kind AS company_type,
    COUNT(ci.id) AS total_cast,
    MAX(m.production_year) AS latest_movie_year
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON at.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
WHERE 
    t.production_year > 2000
AND 
    a.name IS NOT NULL
GROUP BY 
    t.title, a.name, cc.kind
ORDER BY 
    latest_movie_year DESC, total_cast DESC
LIMIT 100;
