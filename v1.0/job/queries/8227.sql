SELECT 
    ak.name AS actor_name,
    ti.title AS movie_title,
    ti.production_year,
    ARRAY_AGG(DISTINCT cn.name) AS company_names,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
    COUNT(DISTINCT c.nr_order) AS total_cast_members
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title ti ON c.movie_id = ti.movie_id
JOIN 
    movie_companies mc ON ti.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON ti.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    ti.production_year BETWEEN 2000 AND 2020
    AND ti.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
GROUP BY 
    ak.name, ti.title, ti.production_year
ORDER BY 
    ti.production_year DESC, actor_name;
