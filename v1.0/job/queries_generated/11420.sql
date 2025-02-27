SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ci.nr_order AS cast_order,
    ct.kind AS company_type,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
GROUP BY 
    t.title, a.name, ci.nr_order, ct.kind
ORDER BY 
    t.title, a.name;
