WITH RECURSIVE CompanyHierarchy AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        0 AS level
    FROM 
        movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id

    UNION ALL

    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ch.level + 1
    FROM 
        movie_companies m
    JOIN CompanyHierarchy ch ON m.movie_id = ch.movie_id
    JOIN company_name c ON m.company_id = c.id
    JOIN company_type ct ON m.company_type_id = ct.id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT ch.company_name, ', ') AS production_companies,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    AVG(mi.info::numeric) AS average_rating,
    ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(DISTINCT mi.info) DESC) AS ranking
FROM 
    cast_info ci
JOIN aka_name a ON ci.person_id = a.person_id
JOIN aka_title t ON ci.movie_id = t.movie_id
LEFT JOIN CompanyHierarchy ch ON ch.movie_id = t.id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
WHERE 
    t.production_year >= 2000 
    AND a.name IS NOT NULL 
    AND ci.note NOT LIKE '%uncredited%'
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT k.keyword) > 5
ORDER BY 
    average_rating DESC, keyword_count DESC;
