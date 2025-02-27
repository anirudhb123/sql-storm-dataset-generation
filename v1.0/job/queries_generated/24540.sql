WITH RECURSIVE actor_hierarchy AS (
    SELECT ci.person_id, 
           a.name AS actor_name, 
           t.title AS movie_title,
           t.production_year,
           ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY t.production_year DESC) AS rn
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN aka_title t ON ci.movie_id = t.movie_id
    WHERE a.name IS NOT NULL
    UNION ALL
    SELECT ah.person_id, 
           ah.actor_name, 
           a.title,
           a.production_year,
           ah.rn + 1
    FROM actor_hierarchy ah
    JOIN cast_info ci ON ah.person_id = ci.person_id
    JOIN aka_title a ON ci.movie_id = a.movie_id
    WHERE ah.rn < 5 AND a.production_year < 2000
),
company_summary AS (
    SELECT mc.movie_id, 
           COUNT(DISTINCT mc.company_id) AS num_companies,
           STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
movie_keyword_summary AS (
    SELECT mk.movie_id,
           COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT ah.actor_name, 
       ah.movie_title, 
       ah.production_year,
       cs.num_companies,
       cs.company_names,
       mks.keyword_count
FROM actor_hierarchy ah
LEFT JOIN company_summary cs ON ah.movie_title = cs.movie_id
LEFT JOIN movie_keyword_summary mks ON ah.movie_title = mks.movie_id
WHERE ah.rn = 1
  AND (cs.num_companies IS NULL OR cs.num_companies > 1)
  AND mks.keyword_count > 0
  AND ah.actor_name LIKE 'A%';
