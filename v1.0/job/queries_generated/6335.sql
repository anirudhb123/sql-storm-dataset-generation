SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.first_name || ' ' || c.last_name AS cast_member,
    ct.kind AS company_type,
    k.keyword AS movie_keyword,
    COUNT(mi.id) AS info_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    ak.name IS NOT NULL
    AND t.production_year >= 2000
    AND ct.kind IN ('Distributor', 'Producer')
GROUP BY 
    ak.name, t.title, cast_member, company_type, movie_keyword
ORDER BY 
    info_count DESC, t.title ASC
LIMIT 100;
