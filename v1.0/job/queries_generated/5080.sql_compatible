
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    ci.note AS cast_note,
    COUNT(kw.keyword) AS keyword_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year >= 2000
GROUP BY 
    a.name, t.title, c.kind, ci.note
ORDER BY 
    keyword_count DESC, a.name ASC;
