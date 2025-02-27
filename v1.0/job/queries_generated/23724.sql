WITH RECURSIVE title_hierarchy AS (
    SELECT t.id AS title_id, 
           t.title AS title_name, 
           t.production_year, 
           t.kind_id, 
           0 AS level
    FROM title t
    WHERE t.production_year > 2000

    UNION ALL

    SELECT t.id, 
           CONCAT(th.title_name, ' -> ', t.title) AS title_name, 
           t.production_year, 
           t.kind_id, 
           th.level + 1
    FROM title_hierarchy th
    JOIN title t ON t.episode_of_id = th.title_id
), cast_roles AS (
    SELECT c.movie_id, 
           COUNT(DISTINCT c.person_id) AS total_cast, 
           STRING_AGG(DISTINCT r.role, ',') AS roles
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id
), movie_keywords AS (
    SELECT mk.movie_id, 
           STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
), movie_companies AS (
    SELECT mc.movie_id, 
           STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT th.title_name, 
       th.production_year, 
       r.kind AS title_kind,
       cr.total_cast,
       cr.roles,
       mk.keywords,
       mc.companies,
       CASE 
           WHEN th.production_year < 2010 THEN 'Old'
           WHEN th.production_year BETWEEN 2010 AND 2015 THEN 'Recent'
           ELSE 'New'
       END AS production_category
FROM title_hierarchy th
JOIN title ti ON th.title_id = ti.id
LEFT JOIN kind_type r ON ti.kind_id = r.id
LEFT JOIN cast_roles cr ON ti.id = cr.movie_id
LEFT JOIN movie_keywords mk ON ti.id = mk.movie_id
LEFT JOIN movie_companies mc ON ti.id = mc.movie_id
WHERE th.level = 0
AND cr.total_cast IS NOT NULL
AND mk.keywords IS NOT NULL
ORDER BY th.production_year DESC, th.title_name;
