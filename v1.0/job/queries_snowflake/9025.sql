
SELECT 
    akn.name AS aka_name,
    tit.title AS movie_title,
    pers.name AS person_name,
    grp.kind AS company_type,
    cnt.name AS company_name,
    tit.production_year,
    COUNT(DISTINCT kw.keyword) AS keyword_count
FROM 
    aka_name akn
JOIN 
    cast_info cti ON akn.person_id = cti.person_id
JOIN 
    title tit ON cti.movie_id = tit.id
JOIN 
    movie_companies mc ON tit.id = mc.movie_id
JOIN 
    company_name cnt ON mc.company_id = cnt.id
JOIN 
    company_type grp ON mc.company_type_id = grp.id
JOIN 
    movie_keyword mwk ON tit.id = mwk.movie_id
JOIN 
    keyword kw ON mwk.keyword_id = kw.id
JOIN 
    name pers ON akn.person_id = pers.imdb_id
WHERE 
    tit.production_year > 2000
    AND grp.kind = 'Production'
GROUP BY 
    akn.name, tit.title, pers.name, grp.kind, cnt.name, tit.production_year
ORDER BY 
    keyword_count DESC, tit.title ASC;
