SELECT 
    title.title AS movie_title,
    aka_name.name AS actor_name,
    company_name.name AS production_company,
    COUNT(DISTINCT movie_keyword.keyword_id) AS keyword_count,
    COUNT(DISTINCT CAST_INFO.person_role_id) AS role_count
FROM 
    title
JOIN 
    movie_companies ON title.id = movie_companies.movie_id
JOIN 
    company_name ON movie_companies.company_id = company_name.id
JOIN 
    cast_info ON title.id = cast_info.movie_id
JOIN 
    aka_name ON cast_info.person_id = aka_name.person_id
JOIN 
    movie_keyword ON title.id = movie_keyword.movie_id
GROUP BY 
    title.title, aka_name.name, company_name.name
HAVING 
    COUNT(DISTINCT movie_keyword.keyword_id) > 5
ORDER BY 
    keyword_count DESC, role_count DESC;
