WITH Recursive_Actor_Movies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS role_order
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
),
Ranked_Movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.actor_id) AS actor_count,
        SUM(CASE WHEN c.nr_order < 3 THEN 1 ELSE 0 END) AS early_roles,
        MAX(CASE WHEN i.info_type_id = 1 THEN i.info END) AS producer_info -- Presuming info_type_id=1 for producer
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        movie_info i ON t.movie_id = i.movie_id
    GROUP BY 
        t.title, t.production_year
),
Selected_Movies AS (
    SELECT 
        title,
        production_year,
        actor_count,
        early_roles,
        producer_info,
        DENSE_RANK() OVER (ORDER BY production_year DESC, actor_count DESC) AS rank
    FROM 
        Ranked_Movies
    WHERE 
        actor_count > 2
        AND production_year IS NOT NULL
)
SELECT 
    sm.title,
    sm.production_year,
    sm.actor_count,
    COALESCE(sm.early_roles, 0) AS early_roles,
    sm.producer_info,
    NULLIF(sm.actor_count, 0) AS non_zero_actor_count, -- Leads to a NULL if actor_count is zero
    CASE 
        WHEN sm.actor_count > 5 THEN 'Ensemble Cast'
        WHEN sm.actor_count BETWEEN 2 AND 5 THEN 'Moderate Cast'
        ELSE 'Minimal Cast'
    END AS cast_category
FROM 
    Selected_Movies sm
LEFT JOIN 
    aka_title at ON sm.title = at.title
WHERE 
    sm.rank <= 10
ORDER BY 
    sm.rank
LIMIT 10 
OFFSET (SELECT COUNT(DISTINCT actor_id) FROM Recursive_Actor_Movies WHERE role_order >= 2) 
-- Offset is based on the count of actors who had more than one appearance
;
