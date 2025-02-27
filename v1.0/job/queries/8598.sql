
SELECT 
    akn.name AS actor_name,
    akn.surname_pcode,
    ttl.title AS movie_title,
    ttl.production_year,
    cn.name AS company_name,
    ct.kind AS company_type,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT cst.id) AS cast_count
FROM 
    aka_name akn
JOIN 
    cast_info cst ON akn.person_id = cst.person_id
JOIN 
    aka_title ttl ON cst.movie_id = ttl.movie_id
JOIN 
    movie_companies mc ON ttl.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON ttl.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    ttl.production_year BETWEEN 2000 AND 2020
    AND akn.name IS NOT NULL
GROUP BY 
    akn.name, akn.surname_pcode, ttl.title, ttl.production_year, cn.name, ct.kind
ORDER BY 
    ttl.production_year DESC, actor_name;
