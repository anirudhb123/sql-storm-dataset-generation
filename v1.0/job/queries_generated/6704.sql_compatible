
SELECT 
    t.title AS movie_title,
    COUNT(DISTINCT ci.person_id) AS num_cast,
    STRING_AGG(DISTINCT ak.name, ',') AS aka_names,
    STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
    c.name AS company_name,
    cp.kind AS company_type,
    MIN(mi.info) AS first_release_date
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type cp ON mc.company_type_id = cp.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Release Date' LIMIT 1)
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, c.name, cp.kind
ORDER BY 
    num_cast DESC
LIMIT 10;
