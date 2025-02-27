WITH RECURSIVE company_hierarchy AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        1 AS level
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    
    UNION ALL
    
    SELECT 
        mc.movie_id,
        c.name,
        ct.kind,
        ch.level + 1
    FROM 
        movie_companies mc
    JOIN 
        company_hierarchy ch ON mc.movie_id = ch.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)

SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT ch.company_name || ' (' || ch.company_type || ')', ', ') AS companies_involved,
    RANK() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank,
    COALESCE(mk.keywords, 'No keywords available') AS keywords
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_hierarchy ch ON t.id = ch.movie_id
LEFT JOIN 
    (SELECT 
         mk.movie_id,
         STRING_AGG(k.keyword, ', ') AS keywords
     FROM 
         movie_keyword mk
     JOIN 
         keyword k ON mk.keyword_id = k.id
     GROUP BY 
         mk.movie_id) mk ON t.id = mk.movie_id
WHERE 
    t.production_year >= 2000
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
GROUP BY 
    t.id, a.name, mk.keywords
HAVING 
    COUNT(DISTINCT mc.company_id) >= 2
ORDER BY 
    movie_title, actor_rank DESC;
