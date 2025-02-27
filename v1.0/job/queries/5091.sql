
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    ct.kind AS company_type,
    STRING_AGG(DISTINCT t2.title, ', ') AS linked_movies,
    COUNT(DISTINCT kw.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_link ml ON t.id = ml.movie_id
LEFT JOIN 
    title t2 ON ml.linked_movie_id = t2.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    t.production_year >= 2000
    AND ct.kind IN ('Distributor', 'Production')
GROUP BY 
    a.name, t.title, t.production_year, ct.kind
ORDER BY 
    t.production_year DESC, actor_name;
