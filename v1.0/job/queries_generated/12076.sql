SELECT 
    akn.name AS aka_name,
    tit.title AS movie_title,
    cst.nr_order AS cast_order,
    prsn.info AS person_info,
    cnt.name AS company_name
FROM 
    aka_name akn
JOIN 
    cast_info cst ON akn.person_id = cst.person_id
JOIN 
    aka_title tit ON cst.movie_id = tit.movie_id
JOIN 
    person_info prsn ON akn.person_id = prsn.person_id
JOIN 
    movie_companies mco ON tit.movie_id = mco.movie_id
JOIN 
    company_name cnt ON mco.company_id = cnt.id
WHERE 
    tit.production_year > 2000
ORDER BY 
    tit.production_year DESC, cst.nr_order;
