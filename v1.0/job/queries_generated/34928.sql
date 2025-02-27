WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           1 AS depth
    FROM aka_title m
    WHERE m.episode_of_id IS NULL
    UNION ALL
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           mh.depth + 1
    FROM aka_title m
    JOIN movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
company_stats AS (
    SELECT mc.movie_id,
           c.name AS company_name,
           ct.kind AS company_type,
           COUNT(DISTINCT m.id) AS movie_count,
           AVG(m.production_year) AS avg_production_year
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN aka_title m ON mc.movie_id = m.id
    GROUP BY mc.movie_id, c.name, ct.kind
),
cast_stats AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT p.id) AS actor_count,
           STRING_AGG(DISTINCT n.name, ', ') AS actor_names
    FROM cast_info ci
    JOIN aka_name n ON ci.person_id = n.person_id
    JOIN person_info pi ON ci.person_id = pi.person_id
    LEFT JOIN complete_cast cc ON ci.movie_id = cc.movie_id
    LEFT JOIN title t ON ci.movie_id = t.id
    WHERE pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Birthplace')
    GROUP BY ci.movie_id
),
final_stats AS (
    SELECT mh.movie_id,
           mh.title,
           mh.production_year,
           COALESCE(cs.actor_count, 0) AS total_actors,
           cs.actor_names,
           COALESCE(comp.movie_count, 0) AS total_companies,
           COALESCE(comp.avg_production_year, 0) AS avg_company_year,
           CASE 
               WHEN mh.depth > 1 THEN 'Subsequent Episode'
               ELSE 'Stand-alone Movie'
           END AS movie_category
    FROM movie_hierarchy mh
    LEFT JOIN cast_stats cs ON mh.movie_id = cs.movie_id
    LEFT JOIN company_stats comp ON mh.movie_id = comp.movie_id
)
SELECT fs.movie_id,
       fs.title,
       fs.production_year,
       fs.total_actors,
       fs.actor_names,
       fs.total_companies,
       fs.avg_company_year,
       fs.movie_category
FROM final_stats fs
WHERE fs.total_actors > 0
ORDER BY fs.production_year DESC, fs.total_actors DESC;
