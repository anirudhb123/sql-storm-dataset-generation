SELECT 
    k.keyword AS Movie_Keyword,
    t.production_year AS Production_Year,
    a.name AS Actor_Name,
    c.kind AS Company_Type,
    COUNT(DISTINCT mv.id) AS Movie_Count,
    STRING_AGG(DISTINCT t.title, ', ') AS Movie_Titles,
    STRING_AGG(DISTINCT a.surname_pcode, ', ') AS Actor_Surnames,
    STRING_AGG(DISTINCT cn.name_pcode_sf, ', ') AS Company_SF_Pcodes
FROM 
    movie_keyword mk
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON mk.movie_id = mi.movie_id
JOIN 
    title t ON mk.movie_id = t.id
LEFT JOIN 
    cast_info ci ON t.id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    t.production_year >= 2000
    AND k.keyword ILIKE '%action%'
GROUP BY 
    k.keyword, t.production_year, a.name, c.kind
ORDER BY 
    COUNT(DISTINCT mv.id) DESC, 
    t.production_year DESC;
