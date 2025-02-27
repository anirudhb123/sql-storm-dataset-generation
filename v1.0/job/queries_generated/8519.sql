SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name) AS company_names,
    COUNT(DISTINCT ci.id) AS cast_count,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ak.name IS NOT NULL
GROUP BY 
    t.id, ak.name, mi.info
ORDER BY 
    t.title, actor_name;
