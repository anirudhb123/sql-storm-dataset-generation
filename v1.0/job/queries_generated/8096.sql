SELECT 
    t.title AS movie_title, 
    GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS actor_names,
    STRING_AGG(DISTINCT co.name, ', ') AS company_names,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    COUNT(DISTINCT mi.info) AS info_count
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
    AND ak.name IS NOT NULL
    AND co.country_code = 'USA'
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%awards%')
GROUP BY 
    t.id
ORDER BY 
    COUNT(DISTINCT ak.name) DESC, 
    t.title ASC
LIMIT 10;
