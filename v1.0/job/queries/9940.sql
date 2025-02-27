
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS company_type,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list,
    COUNT(DISTINCT ci.id) AS cast_count,
    SUM(CASE WHEN mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget') THEN CAST(mi.info AS INTEGER) ELSE 0 END) AS total_budget,
    AVG(CASE WHEN mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Rating') THEN CAST(mi.info AS DECIMAL) ELSE NULL END) AS average_rating
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000 
    AND ct.kind IN ('Distributor', 'Producer')
GROUP BY 
    t.title, a.name, ct.kind
ORDER BY 
    total_budget DESC, average_rating DESC
LIMIT 100;
