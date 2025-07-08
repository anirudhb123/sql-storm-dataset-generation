
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    kt.kind AS cast_type,
    ci.note AS cast_note,
    co.name AS company_name,
    ci.nr_order AS actor_order,
    t.production_year,
    COUNT(k.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
WHERE 
    t.production_year >= 2000
AND 
    kt.kind = 'feature'
GROUP BY 
    a.name, t.title, kt.kind, ci.note, co.name, ci.nr_order, t.production_year
ORDER BY 
    t.production_year DESC, actor_name;
