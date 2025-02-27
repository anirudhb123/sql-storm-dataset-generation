
SELECT 
    t.title AS movie_title, 
    ARRAY_AGG(DISTINCT ak.name) AS aka_names, 
    ARRAY_AGG(DISTINCT c.name) AS cast_names, 
    COUNT(DISTINCT mc.company_id) AS production_companies, 
    COUNT(DISTINCT kw.keyword) AS keywords, 
    COUNT(DISTINCT mi.info) AS additional_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    aka_name ak ON at.id = ak.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    name c ON ci.person_id = c.imdb_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, t.id, t.production_year
ORDER BY 
    t.production_year DESC, t.title;
