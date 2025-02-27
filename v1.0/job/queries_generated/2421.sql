WITH Recursive_Cast AS (
    SELECT c.movie_id, c.person_id, a.name, a.surname_pcode, 
           ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) as role_order
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE a.name IS NOT NULL
),
Movie_Info AS (
    SELECT m.id AS movie_id, m.title, m.production_year,
           COALESCE(mi.info, 'No info') AS info,
           ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY mi.info_type_id) AS info_order
    FROM aka_title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
),
Company_Stats AS (
    SELECT mc.movie_id, COUNT(DISTINCT c.id) AS company_count,
           STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT m.movie_id, m.title, m.production_year, m.info, 
       rc.name AS actor_name, rc.role_order, 
       cs.company_count, cs.company_names
FROM Movie_Info m
LEFT JOIN Recursive_Cast rc ON m.movie_id = rc.movie_id
LEFT JOIN Company_Stats cs ON m.movie_id = cs.movie_id
WHERE m.production_year >= 2000 AND 
      (rc.role_order IS NULL OR rc.role_order < 5)
ORDER BY m.production_year DESC, rc.role_order NULLS LAST;
