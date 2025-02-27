SELECT 
    akn.name AS aka_name,
    tit.title AS movie_title,
    cnt.name AS company_name,
    chi.name AS character_name,
    rty.role AS role,
    mk.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    aka_name akn
JOIN 
    cast_info cst ON akn.person_id = cst.person_id
JOIN 
    title tit ON cst.movie_id = tit.id
JOIN 
    complete_cast cct ON tit.id = cct.movie_id
JOIN 
    company_name cnt ON cct.subject_id = cnt.imdb_id
JOIN 
    char_name chi ON cst.person_id = chi.imdb_id
JOIN 
    role_type rty ON cst.role_id = rty.id
JOIN 
    movie_keyword mk ON tit.id = mk.movie_id
JOIN 
    person_info pi ON akn.person_id = pi.person_id
WHERE 
    tit.production_year > 2000
    AND mk.keyword IS NOT NULL
ORDER BY 
    tit.production_year DESC;
