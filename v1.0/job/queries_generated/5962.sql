SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ci.nr_order AS actor_order,
    c.kind AS company_type,
    COUNT(mk.keyword_id) AS keyword_count,
    MIN(mi.info) AS movie_info,
    MAX(mi.note) AS movie_note
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND a.name IS NOT NULL
GROUP BY 
    t.title, a.name, ci.nr_order, c.kind
ORDER BY 
    keyword_count DESC, movie_title ASC;
