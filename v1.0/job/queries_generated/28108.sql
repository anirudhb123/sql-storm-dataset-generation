SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year AS release_year,
    cd.kind AS genre,
    STRING_AGG(CONCAT_WS('; ', p.info), '; ') AS actor_info,
    STRING_AGG(DISTINCT k.keyword, ', ') AS movie_keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id AND it.info = 'Director'
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    kind_type cd ON t.kind_id = cd.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000
GROUP BY 
    a.name, t.title, t.production_year, cd.kind
ORDER BY 
    t.production_year DESC, a.name;
