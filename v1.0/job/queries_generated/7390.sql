WITH MovieStats AS (
    SELECT t.id AS movie_id, 
           t.title, 
           t.production_year, 
           COUNT(DISTINCT ci.person_id) AS total_cast, 
           COUNT(DISTINCT mk.keyword) AS total_keywords
    FROM title t
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    GROUP BY t.id
),
CompanyStats AS (
    SELECT mc.movie_id, 
           COUNT(DISTINCT co.id) AS total_companies
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY mc.movie_id
),
FinalStats AS (
    SELECT ms.movie_id, 
           ms.title, 
           ms.production_year, 
           ms.total_cast, 
           ms.total_keywords, 
           COALESCE(cs.total_companies, 0) AS total_companies
    FROM MovieStats ms
    LEFT JOIN CompanyStats cs ON ms.movie_id = cs.movie_id
)
SELECT fs.*, 
       CASE 
           WHEN total_cast > 10 THEN 'Large Cast' 
           WHEN total_keywords > 10 THEN 'Rich in Keywords' 
           ELSE 'Standard' 
       END AS movie_category
FROM FinalStats fs
ORDER BY fs.production_year DESC, fs.total_cast DESC;
