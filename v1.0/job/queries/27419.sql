
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    kt.kind AS cast_type,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT pc.person_id) AS co_actors_count
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
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    cast_info pc ON pc.movie_id = ci.movie_id AND pc.person_id <> ci.person_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000 
    AND kt.kind = 'feature'
GROUP BY 
    a.name, t.title, kt.kind, t.production_year
ORDER BY 
    a.name, t.title;
