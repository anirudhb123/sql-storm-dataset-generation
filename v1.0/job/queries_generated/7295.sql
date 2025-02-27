SELECT 
    t.title AS movie_title,
    c.name AS character_name,
    ak.name AS actor_name,
    ci.note AS role_note,
    COUNT(mk.keyword) AS keyword_count,
    GROUP_CONCAT(DISTINCT mk.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name) AS company_names,
    MAX(mi.info) AS additional_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    char_name c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000 
    AND c.name IS NOT NULL
GROUP BY 
    t.id, ak.name, c.name, ci.note
ORDER BY 
    keyword_count DESC, t.title ASC;
