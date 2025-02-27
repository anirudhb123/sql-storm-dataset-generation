
SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    a.production_year,
    COUNT(DISTINCT mi.movie_id) AS movie_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS associated_keywords,
    STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
FROM 
    aka_name n
JOIN 
    cast_info c ON n.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    title a ON t.id = a.id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')
    AND a.production_year BETWEEN 2000 AND 2023
    AND c.nr_order IS NOT NULL
GROUP BY 
    n.name, t.title, a.production_year
HAVING 
    COUNT(DISTINCT mi.movie_id) > 1
ORDER BY 
    movie_count DESC, actor_name ASC;
