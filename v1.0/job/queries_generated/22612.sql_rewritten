WITH RecursiveCTE AS (
    SELECT 
        a.id AS aka_id,
        a.person_id,
        a.name AS aka_name,
        at.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title at ON c.movie_id = at.movie_id
    JOIN 
        title t ON at.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
ActorTitles AS (
    SELECT 
        person_id,
        STRING_AGG(DISTINCT aka_name, ', ') AS titles,
        COUNT(*) AS title_count
    FROM 
        RecursiveCTE
    WHERE 
        rn <= 5
    GROUP BY 
        person_id
),
RecentInfo AS (
    SELECT 
        p.person_id,
        pi.info AS recent_info,
        ROW_NUMBER() OVER (PARTITION BY p.person_id ORDER BY pi.id DESC) AS rn_info
    FROM 
        person_info pi
    JOIN 
        (SELECT DISTINCT person_id FROM cast_info) p ON pi.person_id = p.person_id
    WHERE 
        pi.info IS NOT NULL
)
SELECT 
    ak.person_id,
    ak.titles,
    COALESCE(ri.recent_info, 'No info available') AS recent_info,
    ak.title_count,
    COUNT(DISTINCT c.movie_id) AS total_movies_participated,
    CASE 
        WHEN ak.title_count > 10 THEN 'Prolific Actor'
        WHEN ak.title_count BETWEEN 5 AND 10 THEN 'Moderately Active'
        ELSE 'Newcomer'
    END AS actor_activity_level
FROM 
    ActorTitles ak
LEFT JOIN 
    RecentInfo ri ON ak.person_id = ri.person_id AND ri.rn_info = 1
LEFT JOIN 
    cast_info c ON ak.person_id = c.person_id
GROUP BY 
    ak.person_id, ak.titles, ri.recent_info, ak.title_count
HAVING 
    ak.title_count > 2 
ORDER BY 
    actor_activity_level DESC, title_count DESC, ak.person_id;