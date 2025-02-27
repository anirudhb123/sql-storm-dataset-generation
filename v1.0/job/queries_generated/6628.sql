SELECT 
    at.title AS movie_title,
    ak.name AS actor_name,
    COUNT(cc.person_id) AS total_cast,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    ti.info AS additional_info
FROM 
    aka_title at
JOIN 
    cast_info cc ON at.id = cc.movie_id
JOIN 
    aka_name ak ON cc.person_id = ak.person_id
JOIN 
    movie_keyword mk ON at.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
JOIN 
    movie_info mi ON at.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    at.production_year > 2000
    AND ak.name IS NOT NULL
GROUP BY 
    at.title, ak.name, ti.info
ORDER BY 
    total_cast DESC, movie_title ASC;
