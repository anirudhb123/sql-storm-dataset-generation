WITH RECURSIVE Movie_CTE AS (
    SELECT t.id AS movie_id, t.title, t.production_year, t.kind_id, 1 AS depth
    FROM aka_title t
    WHERE t.production_year >= 2000
    UNION ALL
    SELECT t.id, t.title, t.production_year, t.kind_id, depth + 1
    FROM aka_title t
    JOIN Movie_CTE m ON t.id = m.movie_id
    WHERE m.depth < 5
),
Actor_Info AS (
    SELECT a.name, c.movie_id, r.role, 
           DENSE_RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN role_type r ON c.role_id = r.id
),
Company_CTE AS (
    SELECT m.id AS movie_id, 
           ARRAY_AGG(DISTINCT cn.name) AS company_names,
           COUNT(DISTINCT m.id) AS company_count
    FROM movie_companies m
    JOIN company_name cn ON m.company_id = cn.id
    GROUP BY m.id
),
Info_Count AS (
    SELECT movie_id, COUNT(*) AS info_count
    FROM movie_info
    GROUP BY movie_id
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(ac.name, 'Unknown Actor') AS actor_name,
    ac.actor_rank,
    cc.company_names,
    ic.info_count,
    CASE 
        WHEN ic.info_count > 10 THEN 'High Info'
        WHEN ic.info_count BETWEEN 5 AND 10 THEN 'Medium Info'
        ELSE 'Low Info'
    END AS info_level
FROM Movie_CTE m
LEFT JOIN Actor_Info ac ON m.movie_id = ac.movie_id
LEFT JOIN Company_CTE cc ON m.movie_id = cc.movie_id
LEFT JOIN Info_Count ic ON m.movie_id = ic.movie_id
ORDER BY m.production_year DESC, m.title ASC, ac.actor_rank
LIMIT 50;
