
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    pc.kind AS production_company,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT ci.id) AS cast_count,
    ROUND(AVG(CASE WHEN mi.note IS NOT NULL THEN 1 ELSE 0 END), 2) AS avg_notes
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    comp_cast_type pc ON mc.company_type_id = pc.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND k.keyword LIKE '%Drama%'
GROUP BY 
    t.title, a.name, pc.kind, k.keyword, mi.note
HAVING 
    COUNT(DISTINCT ci.id) > 2
ORDER BY 
    avg_notes DESC, cast_count DESC;
