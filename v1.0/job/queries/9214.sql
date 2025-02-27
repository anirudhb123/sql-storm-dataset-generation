
SELECT 
    t.title AS movie_title, 
    p.name AS actor_name, 
    COUNT(ka.id) AS alias_count, 
    STRING_AGG(k.keyword, ',') AS keywords, 
    c.kind AS company_type
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ka ON ci.person_id = ka.person_id
JOIN 
    name p ON ka.person_id = p.imdb_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000
GROUP BY 
    t.title, p.name, c.kind
ORDER BY 
    alias_count DESC, movie_title ASC
FETCH FIRST 50 ROWS ONLY;
