SELECT 
    n.name AS actor_name,
    a.title AS movie_title,
    a.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    c.kind AS company_type,
    CASE 
        WHEN c.note IS NOT NULL THEN c.note 
        ELSE 'No Note' 
    END AS company_note
FROM 
    aka_name n
JOIN 
    cast_info ci ON n.person_id = ci.person_id
JOIN 
    aka_title a ON ci.movie_id = a.movie_id
JOIN 
    movie_companies mc ON a.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON a.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    n.name IS NOT NULL
    AND a.production_year >= 2000
    AND c.country_code = 'USA'
GROUP BY 
    n.name, a.title, a.production_year, c.kind, c.note
ORDER BY 
    a.production_year DESC, n.name ASC;
