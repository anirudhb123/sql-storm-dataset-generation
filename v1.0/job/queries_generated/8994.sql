SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_kind,
    co.name AS company_name,
    m.production_year,
    GROUP_CONCAT(DISTINCT k.keyword SEPARATOR ', ') AS keywords,
    COUNT(DISTINCT t.id) OVER (PARTITION BY a.person_id) AS movie_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.imdb_index IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2023
    AND co.country_code = 'USA'
GROUP BY 
    a.id, t.id, c.kind, co.id, m.production_year
ORDER BY 
    movie_count DESC, actor_name ASC;
