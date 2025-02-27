WITH movie_details AS (
    SELECT 
        t.title, 
        t.production_year, 
        c.type AS company_type, 
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_type c ON mc.company_type_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, c.type
),
person_cast_info AS (
    SELECT 
        a.name AS actor_name, 
        t.title AS movie_title, 
        t.production_year, 
        r.role
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN title t ON ci.movie_id = t.id
    JOIN role_type r ON ci.role_id = r.id
    WHERE a.name IS NOT NULL
),
top_companies AS (
    SELECT 
        c.name, 
        COUNT(mc.movie_id) AS movie_count
    FROM company_name c
    JOIN movie_companies mc ON c.id = mc.company_id
    GROUP BY c.id
    ORDER BY movie_count DESC
    LIMIT 5
)
SELECT 
    md.title,
    md.production_year,
    md.company_type,
    md.keywords,
    pci.actor_name,
    pci.role,
    COALESCE(tc.name, 'Independent') AS production_company
FROM movie_details md
JOIN person_cast_info pci ON md.title = pci.movie_title AND md.production_year = pci.production_year
LEFT JOIN top_companies tc ON md.company_type = tc.name
WHERE md.keywords LIKE '%action%'
ORDER BY md.production_year DESC, md.title;
