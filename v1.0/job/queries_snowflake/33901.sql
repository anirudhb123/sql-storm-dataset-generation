
WITH RECURSIVE movie_cte AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS level
    FROM aka_title m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT m.id, m.title, m.production_year, cte.level + 1
    FROM aka_title m
    JOIN movie_link ml ON ml.linked_movie_id = m.id
    JOIN movie_cte cte ON cte.movie_id = ml.movie_id
    WHERE cte.level < 3
),
average_cast AS (
    SELECT c.movie_id,
           AVG(CASE WHEN p.info IS NOT NULL THEN 1 ELSE 0 END) AS average_role_count
    FROM cast_info c
    LEFT JOIN person_info p ON p.person_id = c.person_id
    GROUP BY c.movie_id
),
movie_keywords AS (
    SELECT mk.movie_id, 
           LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY mk.movie_id
),
company_details AS (
    SELECT mc.movie_id,
           ARRAY_AGG(DISTINCT cn.name) AS companies
    FROM movie_companies mc
    JOIN company_name cn ON cn.id = mc.company_id
    GROUP BY mc.movie_id
)

SELECT m.movie_id,
       m.title,
       m.production_year,
       COALESCE(ak.keywords, 'No Keywords') AS keywords,
       COALESCE(cd.companies, ARRAY_AGG('No Companies')) AS companies,
       COALESCE(ac.average_role_count, 0) AS average_role_count
FROM movie_cte m
LEFT JOIN movie_keywords ak ON ak.movie_id = m.movie_id
LEFT JOIN company_details cd ON cd.movie_id = m.movie_id
LEFT JOIN average_cast ac ON ac.movie_id = m.movie_id
WHERE m.production_year >= 2000
GROUP BY m.movie_id, m.title, m.production_year, ak.keywords, cd.companies, ac.average_role_count
ORDER BY m.production_year DESC, average_role_count DESC
LIMIT 100;
