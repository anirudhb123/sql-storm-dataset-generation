WITH RECURSIVE ActorHierarchy AS (
    SELECT ci.person_id, t.title, t.production_year, ci.nr_order,
           ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY t.production_year DESC) as rn
    FROM cast_info ci
    JOIN aka_title t ON ci.movie_id = t.id
    WHERE ci.nr_order IS NOT NULL
),

KeywordCount AS (
    SELECT mk.movie_id, COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),

CompanyInfo AS (
    SELECT mc.movie_id, cn.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE cn.country_code IS NOT NULL AND mc.note IS NOT NULL
),

CompleteInfo AS (
    SELECT c.movie_id, 
           COUNT(DISTINCT ci.person_id) AS cast_count,
           COUNT(DISTINCT kw.keyword) AS total_keywords,
           STRING_AGG(DISTINCT comp.company_name, ', ') AS companies
    FROM complete_cast c
    LEFT JOIN cast_info ci ON c.subject_id = ci.person_id
    LEFT JOIN KeywordCount kw ON c.movie_id = kw.movie_id
    LEFT JOIN CompanyInfo comp ON comp.movie_id = c.movie_id
    GROUP BY c.movie_id
),

PerformanceMetrics AS (
    SELECT ah.person_id, 
           COUNT(DISTINCT ah.title) AS titles_count,
           AVG(CASE WHEN ah.rn = 1 THEN ah.production_year END) AS avg_year_first_role,
           MAX(ah.production_year) AS last_role_year
    FROM ActorHierarchy ah
    GROUP BY ah.person_id
)

SELECT p.person_id, 
       p.title AS movie_title, 
       pm.titles_count, 
       pm.avg_year_first_role, 
       COALESCE(cast_info.cast_count, 0) AS cast_count, 
       COALESCE(ci.total_keywords, 0) AS total_keywords, 
       ci.companies
FROM (SELECT DISTINCT p.id AS person_id, a.title
      FROM aka_name p
      JOIN cast_info ci ON p.person_id = ci.person_id
      JOIN aka_title a ON ci.movie_id = a.id
      WHERE p.name ILIKE '%Smith%' OR p.name LIKE 'J%') AS p
LEFT JOIN PerformanceMetrics pm ON p.person_id = pm.person_id
LEFT JOIN CompleteInfo ci ON ci.movie_id = (SELECT id FROM aka_title WHERE title = p.title LIMIT 1)
LEFT JOIN film_cast_info cast_info ON cast_info.movie_id = (SELECT id FROM aka_title WHERE title = p.title LIMIT 1)
ORDER BY pm.avg_year_first_role DESC NULLS LAST, p.person_id;

