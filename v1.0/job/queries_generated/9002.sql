SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    ct.kind AS company_type,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
    string_agg(DISTINCT ci.note) AS cast_notes
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000 
    AND ct.kind IS NOT NULL
GROUP BY 
    a.name, t.title, c.nr_order, ct.kind
ORDER BY 
    a.name, t.title, c.nr_order;
