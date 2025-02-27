SELECT 
    ak.name AS aka_name,
    tit.title AS movie_title,
    pers.name AS person_name,
    ct.kind AS company_type,
    COUNT(DISTINCT mci.company_id) AS num_companies,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ti.info AS additional_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title tit ON ci.movie_id = tit.id
JOIN 
    movie_companies mci ON tit.id = mci.movie_id
JOIN 
    company_type ct ON mci.company_type_id = ct.id
JOIN 
    movie_keyword mk ON tit.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
LEFT JOIN 
    movie_info ti ON tit.id = ti.movie_id
WHERE 
    tit.production_year BETWEEN 2000 AND 2023
    AND ak.name IS NOT NULL
    AND kw.keyword IS NOT NULL
GROUP BY 
    ak.id, tit.id, pers.id, ct.id, ti.info
ORDER BY 
    num_companies DESC, ak.name ASC;
