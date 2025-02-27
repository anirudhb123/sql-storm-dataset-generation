WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorTitles AS (
    SELECT 
        ca.person_id,
        rt.title,
        rt.production_year,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY rt.production_year DESC) AS recent_title_rank
    FROM 
        cast_info ca
    JOIN 
        RankedTitles rt ON ca.movie_id = rt.title_id
),
UniqueActors AS (
    SELECT 
        DISTINCT a.id AS actor_id,
        a.name,
        COUNT(DISTINCT att.title) AS title_count,
        AVG(EXTRACT(YEAR FROM CURRENT_DATE) - att.production_year) AS avg_year_difference
    FROM 
        aka_name a
    LEFT JOIN 
        ActorTitles att ON a.person_id = att.person_id
    GROUP BY 
        a.id, a.name
),
TopActors AS (
    SELECT 
        ua.actor_id,
        ua.name,
        ua.title_count,
        ua.avg_year_difference,
        CASE 
            WHEN ua.title_count = 0 THEN 'No Titles'
            WHEN ua.avg_year_difference IS NULL THEN 'Recent Production'
            ELSE 'Active Actor'
        END AS actor_status
    FROM 
        UniqueActors ua
    WHERE 
        (ua.title_count >= 1 AND ua.avg_year_difference < 10)
        OR (ua.title_count = 0)
)

SELECT 
    ta.actor_id,
    ta.name,
    COALESCE(ta.title_count, 0) AS title_count,
    COALESCE(ta.avg_year_difference, 'N/A') AS avg_year_difference,
    ta.actor_status,
    STRING_AGG(DISTINCT rt.title, ', ') AS titles
FROM 
    TopActors ta
LEFT JOIN 
    ActorTitles rt ON ta.actor_id = rt.person_id AND rt.recent_title_rank <= 5
GROUP BY 
    ta.actor_id, ta.name, ta.title_count, ta.avg_year_difference, ta.actor_status
HAVING 
    ta.actor_status = 'Active Actor'
ORDER BY 
    ta.title_count DESC, ta.avg_year_difference ASC;


