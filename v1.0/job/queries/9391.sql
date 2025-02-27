
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS company_type,
    STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    MAX(mi.info) AS movie_info
FROM 
    aka_title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000
AND 
    c.kind LIKE 'Distributor%'
GROUP BY 
    t.title, a.name, c.kind
ORDER BY 
    movie_title, actor_name;
