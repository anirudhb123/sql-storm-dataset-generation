
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    kt.kind AS cast_type,
    co.name AS company_name,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
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
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    kind_type kt ON t.kind_id = kt.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND kt.kind = 'Feature'
    AND co.country_code = 'USA'
GROUP BY 
    a.name, t.title, kt.kind, co.name, t.production_year
ORDER BY 
    t.production_year DESC, a.name;
