WITH RecursiveNames AS (
    SELECT p.id AS person_id, a.name, a.imdb_index, 
           ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY a.name) AS rn 
    FROM aka_name a
    JOIN name p ON a.person_id = p.imdb_id
    WHERE a.name IS NOT NULL
), 
TitleInfo AS (
    SELECT t.id AS title_id, t.title, t.production_year, t.kind_id, 
           COUNT(DISTINCT mc.company_id) AS company_count,
           SUM(CASE WHEN mc.note IS NULL THEN 1 ELSE 0 END) AS null_company_notes 
    FROM aka_title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    GROUP BY t.id
), 
RoleInfo AS (
    SELECT c.movie_id, c.person_id AS actor_id, rt.role AS role_name,
           ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM cast_info c
    JOIN role_type rt ON c.person_role_id = rt.id
), 
MovieKeywords AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)

SELECT t.title AS movie_title, 
       t.production_year,
       tn.name AS actor_name,
       ri.role_name AS role,
       ti.company_count,
       ti.null_company_notes,
       CASE WHEN ti.company_count > 0 THEN 'Produced' ELSE 'Not Produced' END AS production_status,
       COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM TitleInfo ti
JOIN title t ON ti.title_id = t.id
LEFT JOIN RoleInfo ri ON t.id = ri.movie_id
LEFT JOIN RecursiveNames tn ON ri.actor_id = tn.person_id AND tn.rn = 1 
LEFT JOIN MovieKeywords mk ON t.id = mk.movie_id
WHERE t.production_year IS NOT NULL
AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Feature%')
ORDER BY t.production_year DESC, t.title, actor_name
FETCH FIRST 50 ROWS ONLY;
