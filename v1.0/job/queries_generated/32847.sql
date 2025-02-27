WITH RECURSIVE CompanyHierarchy AS (
    SELECT id AS company_id, name, country_code, 1 AS level
    FROM company_name
    WHERE country_code IS NOT NULL
    
    UNION ALL
    
    SELECT mc.company_id, cn.name, cn.country_code, ch.level + 1
    FROM movie_companies mc
    JOIN CompanyHierarchy ch ON mc.movie_id = ch.company_id
    JOIN company_name cn ON mc.company_id = cn.id
),
MovieDetails AS (
    SELECT 
        akn.name AS actor_name,
        akn.person_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(ct.id) AS role_count
    FROM aka_name akn
    JOIN cast_info ci ON akn.person_id = ci.person_id
    JOIN aka_title mt ON ci.movie_id = mt.movie_id
    LEFT JOIN role_type rt ON ci.role_id = rt.id
    WHERE mt.production_year >= 2000
    GROUP BY akn.name, akn.person_id, mt.title, mt.production_year
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY mk.movie_id
)
SELECT 
    md.actor_name,
    md.movie_title,
    md.production_year,
    kc.keyword_count,
    COALESCE(ch.name, 'No Company') AS company_name,
    ch.level,
    ROW_NUMBER() OVER (PARTITION BY md.person_id ORDER BY md.role_count DESC) AS actor_rank
FROM MovieDetails md
LEFT JOIN KeywordCounts kc ON md.movie_title = kc.movie_id
LEFT JOIN movie_companies mc ON md.movie_title = mc.movie_id
LEFT JOIN CompanyHierarchy ch ON mc.company_id = ch.company_id
WHERE md.role_count > 1
ORDER BY md.production_year DESC, md.actor_name;
