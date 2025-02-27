SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    COALESCE(ci.note, 'N/A') AS role_note,
    ckt.kind AS company_type,
    m.production_year,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
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
    company_type ckt ON mc.company_type_id = ckt.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, ci.note, ckt.kind, m.production_year
ORDER BY 
    actor_name, movie_title;
