SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    m.kind_id,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords_used,
    char.name AS character_name
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    complete_cast cc ON m.id = cc.movie_id
LEFT JOIN 
    char_name char ON cc.subject_id = char.id
WHERE 
    a.name ILIKE '%Smith%' 
    AND m.production_year > 2000 
GROUP BY 
    a.name, m.title, m.production_year, m.kind_id, char.name
ORDER BY 
    num_companies DESC, m.production_year ASC;