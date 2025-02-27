SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    COUNT(DISTINCT k.keyword) AS associated_keywords,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
    COUNT(CASE WHEN c.note IS NOT NULL THEN 1 END) AS non_null_company_notes
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2022
    AND a.name IS NOT NULL
GROUP BY 
    t.title, a.name
ORDER BY 
    associated_keywords DESC, movie_title ASC;

This query gathers data about movies from the years 2000 to 2022, including the movie title, actor names, the count of associated keywords, a string aggregation of company types, and the count of non-null notes from movie companies. It uses multiple joins to consolidate data from different related tables, while employing grouping and ordering to achieve a structured output.
