WITH RECURSIVE company_hierarchy AS (
    SELECT c.id AS company_id, c.name AS company_name, 0 AS level
    FROM company_name c
    WHERE c.country_code IS NOT NULL
    
    UNION ALL
    
    SELECT c.id, c.name, ch.level + 1
    FROM company_name c
    JOIN movie_companies mc ON mc.company_id = c.id
    JOIN company_hierarchy ch ON mc.movie_id = ch.company_id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    EXTRACT(YEAR FROM t.production_year) AS production_year,
    CASE 
        WHEN ci.role_id IS NOT NULL THEN 'Actor'
        ELSE 'Unknown Role'
    END AS role,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    COUNT(DISTINCT mi.info_type_id) AS movie_info_count,
    AVG(mi.info IS NOT NULL)::int AS info_null_percentage
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN aka_title t ON ci.movie_id = t.movie_id
LEFT JOIN movie_companies mc ON t.movie_id = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN movie_info mi ON t.movie_id = mi.movie_id
LEFT JOIN kind_type kt ON t.kind_id = kt.id
WHERE a.name IS NOT NULL
GROUP BY a.id, t.id, t.title, t.production_year
ORDER BY production_year DESC, actor_name
LIMIT 50;

WITH enable_rows AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT t.title) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY COUNT(DISTINCT t.title) DESC) AS row_num
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title t ON ci.movie_id = t.movie_id
    GROUP BY a.person_id
)
SELECT 
    a.name AS actor_name,
    er.movie_count
FROM aka_name a
JOIN enable_rows er ON a.person_id = er.person_id
WHERE er.row_num = 1;
