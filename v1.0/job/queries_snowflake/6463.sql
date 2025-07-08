
SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    c.note AS cast_note, 
    ct.kind AS company_type, 
    AVG(CAST(mi.info AS numeric)) AS average_info_rating, 
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ct.kind = 'Distributor'
    AND t.production_year >= 2000
GROUP BY 
    ak.name, t.title, c.note, ct.kind, mi.info
HAVING 
    COUNT(DISTINCT k.keyword) > 5
ORDER BY 
    average_info_rating DESC, aka_name ASC;
