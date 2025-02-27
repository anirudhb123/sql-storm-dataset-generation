SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_info,
    c.kind AS company_kind,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    MIN(m.production_year) AS earliest_movie_year,
    MAX(m.production_year) AS latest_movie_year
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    p.info_type_id = (SELECT id FROM info_type WHERE info = 'bio')
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    t.id, a.name, p.info, c.kind
ORDER BY 
    latest_movie_year DESC, keyword_count DESC;
