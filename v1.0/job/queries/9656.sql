
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    kt.kind AS kind, 
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords, 
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND ci.nr_order < 5
    AND it.info = 'Synopsis'
GROUP BY 
    a.name, t.title, t.production_year, kt.kind
ORDER BY 
    t.production_year DESC, a.name;
