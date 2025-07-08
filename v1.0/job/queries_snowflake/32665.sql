WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 
           1 AS level, 
           CAST(mt.title AS VARCHAR(255)) AS path
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 
           mh.level + 1 AS level,
           CAST(mh.path || ' -> ' || mt.title AS VARCHAR(255)) AS path
    FROM aka_title mt
    INNER JOIN movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
cast_roles AS (
    SELECT ci.movie_id, 
           ct.kind AS role_type, 
           COUNT(*) AS actor_count
    FROM cast_info ci
    JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY ci.movie_id, ct.kind
),
top_movies AS (
    SELECT mh.movie_id, mh.title, mh.production_year, 
           ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_mv
    FROM movie_hierarchy mh
    LEFT JOIN cast_info ci ON mh.movie_id = ci.movie_id
    GROUP BY mh.movie_id, mh.title, mh.production_year
    HAVING COUNT(DISTINCT ci.person_id) > 0
),
actor_details AS (
    SELECT ak.name, 
           COALESCE(p.country_code, 'UNKNOWN') AS country, 
           ak.person_id,
           SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS appearances
    FROM aka_name ak
    LEFT JOIN cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN company_name p ON ci.movie_id = p.id
    GROUP BY ak.name, ak.person_id, p.country_code
)
SELECT tm.title AS movie_title,
       tm.production_year,
       cr.role_type,
       ad.name AS actor_name,
       ad.country,
       ad.appearances,
       mh.path
FROM top_movies tm
JOIN cast_roles cr ON tm.movie_id = cr.movie_id
JOIN actor_details ad ON ad.person_id = cr.movie_id
JOIN movie_hierarchy mh ON tm.movie_id = mh.movie_id
WHERE tm.rank_mv <= 10
ORDER BY tm.production_year DESC, ad.appearances DESC;