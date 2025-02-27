WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ca.id AS actor_id,
        ca.person_id,
        ca.movie_id,
        1 AS level
    FROM cast_info ca
    WHERE ca.person_role_id IS NOT NULL

    UNION ALL

    SELECT 
        ca.id AS actor_id,
        ca.person_id,
        ca.movie_id,
        ah.level + 1
    FROM cast_info ca
    INNER JOIN ActorHierarchy ah ON ca.movie_id = ah.movie_id
    WHERE ca.id != ah.actor_id
),

MovieStats AS (
    SELECT 
        mt.movie_id,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        COUNT(DISTINCT kw.keyword) AS total_keywords,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN movie_keyword mw ON mw.movie_id = mt.movie_id
    LEFT JOIN keyword kw ON kw.id = mw.keyword_id
    GROUP BY mt.movie_id
),

CompanyInfo AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT cn.id) AS total_companies
    FROM movie_companies mc
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)

SELECT 
    mt.title,
    mt.production_year,
    COALESCE(ms.total_cast, 0) AS total_cast,
    COALESCE(ms.total_keywords, 0) AS total_keywords,
    COALESCE(ms.avg_order, 0) AS avg_order,
    COALESCE(ci.companies, '{}') AS companies,
    ci.total_companies,
    COUNT(DISTINCT ah.actor_id) AS total_active_actors,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
FROM aka_title mt
LEFT JOIN MovieStats ms ON mt.movie_id = ms.movie_id
LEFT JOIN CompanyInfo ci ON mt.movie_id = ci.movie_id
LEFT JOIN ActorHierarchy ah ON mt.movie_id = ah.movie_id
LEFT JOIN aka_name ak ON ak.person_id = ah.person_id
WHERE mt.production_year >= 2000
AND ms.avg_order > 2
GROUP BY mt.title, mt.production_year, ci.total_companies
ORDER BY mt.production_year DESC, total_cast DESC;
