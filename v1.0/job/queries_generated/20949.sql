WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS year_order
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
),
ActorInfoCTE AS (
    SELECT 
        a.name AS actor_name,
        c.movie_id,
        COUNT(*) AS role_count,
        SUM(CASE WHEN c.note IS NULL THEN 1 ELSE 0 END) AS nullable_notes_count
    FROM cast_info c
    JOIN aka_name a ON a.person_id = c.person_id
    GROUP BY a.name, c.movie_id
),
MovieDetailsCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(gc.company_name, 'Unknown Company') AS company_name,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_order
    FROM aka_title m
    LEFT JOIN movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN company_name gc ON gc.id = mc.company_id
    WHERE m.production_year BETWEEN 2000 AND 2020
),
CombinedInfo AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        ai.actor_name,
        ai.role_count,
        md.company_name,
        md.title_order
    FROM RecursiveMovieCTE rm
    LEFT JOIN ActorInfoCTE ai ON ai.movie_id = rm.movie_id
    LEFT JOIN MovieDetailsCTE md ON md.movie_id = rm.movie_id
)
SELECT 
    title,
    production_year,
    COUNT(DISTINCT actor_name) AS distinct_actors,
    MAX(role_count) AS max_roles,
    STRING_AGG(DISTINCT company_name, ', ') AS companies,
    SUM(CASE WHEN role_count IS NULL THEN 1 ELSE 0 END) AS movies_with_no_roles
FROM CombinedInfo
WHERE title IS NOT NULL
GROUP BY title, production_year
HAVING MAX(role_count) > 2 AND COUNT(DISTINCT actor_name) > 1
ORDER BY production_year DESC, max_roles DESC
LIMIT 20;
