
SELECT 
    t.title AS movie_title,
    n.name AS actor_name,
    k.keyword AS movie_keyword,
    cp.kind AS company_type,
    COUNT(DISTINCT ci.id) AS total_cast,
    AVG(CASE WHEN mi.info_type_id = it.id THEN LENGTH(mi.info) END) AS avg_info_length,
    SUM(CASE WHEN mk.keyword_id IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.id = cc.subject_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    name n ON an.person_id = n.imdb_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type cp ON mc.company_type_id = cp.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    t.production_year >= 2000
    AND n.gender = 'F'
GROUP BY 
    t.title, n.name, k.keyword, cp.kind, it.id
HAVING 
    COUNT(DISTINCT ci.id) > 5
ORDER BY 
    total_cast DESC, movie_title ASC;
