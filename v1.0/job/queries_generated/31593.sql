WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS row_num
    FROM aka_title mt
    LEFT JOIN complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    GROUP BY mt.id, mt.title, mt.production_year
),
ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year DESC) AS actor_year_rank
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN aka_title mt ON ci.movie_id = mt.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mn.name) AS total_companies
    FROM movie_companies mc
    JOIN company_name mn ON mc.company_id = mn.id
    WHERE mn.country_code IS NOT NULL
    GROUP BY mc.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.total_cast,
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    COALESCE(c.total_companies, 0) AS total_companies,
    STRING_AGG(DISTINCT a.actor_name, ', ') AS actors
FROM RecursiveMovieCTE r
LEFT JOIN MovieKeywords k ON r.movie_id = k.movie_id
LEFT JOIN MovieCompanies c ON r.movie_id = c.movie_id
LEFT JOIN ActorInfo a ON r.movie_id = a.production_year
WHERE r.total_cast > 0 
  AND r.production_year >= 2000 
  AND r.title IS NOT NULL
GROUP BY r.movie_id, r.title, r.production_year, r.total_cast, k.keywords, c.total_companies
HAVING COUNT(a.actor_name) > 1
ORDER BY r.production_year DESC, r.total_cast DESC;
