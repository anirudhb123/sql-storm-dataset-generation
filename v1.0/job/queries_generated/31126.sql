WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        ca.nr_order,
        1 AS level
    FROM cast_info ca
    WHERE ca.role_id IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ca.person_id,
        ca.movie_id,
        ca.nr_order,
        ah.level + 1
    FROM cast_info ca
    JOIN ActorHierarchy ah ON ca.movie_id = ah.movie_id 
    WHERE ca.person_id != ah.person_id
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        m.company_id,
        m.note AS company_note,
        ak.name AS actor_name,
        ROW_NUMBER() OVER(PARTITION BY t.id ORDER BY ca.nr_order) AS actor_sequence
    FROM aka_title t
    JOIN cast_info ca ON t.id = ca.movie_id
    LEFT JOIN aka_name ak ON ca.person_id = ak.person_id
    LEFT JOIN movie_companies m ON t.id = m.movie_id
    WHERE t.production_year >= 2000
),
HighestRatedMovies AS (
    SELECT 
        md.title,
        md.production_year,
        COUNT(*) AS actor_count
    FROM MovieDetails md
    GROUP BY md.title, md.production_year
    HAVING COUNT(*) > 5
)
SELECT 
    h.title,
    h.production_year,
    h.actor_count,
    COALESCE(cn.name, 'Unknown Company') AS production_company,
    MAX(CASE WHEN md.actor_sequence = 1 THEN md.actor_name END) AS Lead_Actor,
    (SELECT COUNT(DISTINCT movie_id) FROM movie_info WHERE info_type_id = 1 
     AND info LIKE '%blockbuster%') AS Blockbuster_Count
FROM HighestRatedMovies h
LEFT JOIN movie_companies mc ON h.title = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN MovieDetails md ON h.title = md.title
GROUP BY h.title, h.production_year, h.actor_count, cn.name
ORDER BY h.actor_count DESC, h.production_year DESC
LIMIT 10;
