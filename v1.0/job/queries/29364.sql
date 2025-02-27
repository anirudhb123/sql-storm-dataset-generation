
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ci.note AS cast_note,
    pi.info AS person_info,
    COUNT(mk.id) AS keyword_count,
    MIN(t.production_year) AS earliest_release_year,
    MAX(t.production_year) AS latest_release_year
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    cn.country_code = 'USA' 
    AND t.production_year BETWEEN 2000 AND 2022
    AND ci.nr_order IS NOT NULL
GROUP BY 
    t.title, a.name, ci.note, pi.info
HAVING 
    COUNT(mk.id) > 5
ORDER BY 
    earliest_release_year ASC, latest_release_year DESC, movie_title ASC;
