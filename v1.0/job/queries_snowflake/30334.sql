
WITH RECURSIVE CompanyHierarchy AS (
    SELECT c.id AS company_id, c.name, mc.movie_id, ct.kind AS company_type 
    FROM company_name c
    JOIN movie_companies mc ON c.id = mc.company_id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE c.country_code = 'USA'
    
    UNION ALL
    
    SELECT c.id AS company_id, c.name, mc.movie_id, ct.kind AS company_type 
    FROM company_name c
    JOIN movie_companies mc ON c.id = mc.company_id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN CompanyHierarchy ch ON c.id = ch.company_id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    COUNT(DISTINCT ci.person_role_id) AS num_actors,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_present_ratio,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY a.name) AS actor_rank
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN aka_title t ON ci.movie_id = t.movie_id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
JOIN movie_companies mc ON t.id = mc.movie_id
LEFT JOIN CompanyHierarchy ch ON mc.company_id = ch.company_id
WHERE t.production_year BETWEEN 1990 AND 2023
  AND (a.name ILIKE '%Smith%' OR a.name IS NULL)
GROUP BY a.name, t.title, t.production_year
HAVING COUNT(DISTINCT ci.person_role_id) > 2
ORDER BY t.production_year DESC, actor_rank;
