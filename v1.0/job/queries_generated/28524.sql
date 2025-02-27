SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.gender AS person_gender,
    ki.keyword AS movie_keyword,
    COALESCE(mn.name, 'Unknown Company') AS company_name,
    COUNT(DISTINCT m.id) AS total_movies_linked,
    STRING_AGG(DISTINCT info.info, ', ') AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    name p ON a.person_id = p.imdb_id
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
LEFT JOIN 
    company_name mn ON mc.company_id = mn.id
LEFT JOIN 
    movie_info mi ON t.movie_id = mi.movie_id
LEFT JOIN 
    info_type info ON mi.info_type_id = info.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND a.name IS NOT NULL
GROUP BY 
    a.name, 
    t.title, 
    c.nr_order, 
    p.gender, 
    ki.keyword,
    mn.name
ORDER BY 
    total_movies_linked DESC, 
    aka_name ASC;
