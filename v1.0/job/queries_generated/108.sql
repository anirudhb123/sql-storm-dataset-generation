WITH MovieTitleCTE AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), 
ActorRolesCTE AS (
    SELECT 
        a.name AS actor_name,
        c.movie_id,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
), 
TitleInfoCTE AS (
    SELECT 
        t.title AS movie_title,
        ti.info AS production_note
    FROM 
        title t
    LEFT JOIN 
        movie_info ti ON t.id = ti.movie_id 
    WHERE 
        ti.info_type_id = (SELECT id FROM info_type WHERE info = 'Production Notes')
)

SELECT 
    m.title AS MovieTitle,
    m.production_year AS ProductionYear,
    COALESCE(a.actor_name, 'Unknown') AS ActorName,
    COUNT(DISTINCT m.title_id) AS TitleCount,
    MAX(a.role_name) AS TopRole,
    CASE 
        WHEN m.company_count > 0 THEN 'Produced'
        ELSE 'Not Produced'
    END AS ProductionStatus,
    t.production_note AS ProductionNote
FROM 
    MovieTitleCTE m
LEFT JOIN 
    ActorRolesCTE a ON m.title_id = a.movie_id
LEFT JOIN 
    TitleInfoCTE t ON m.title = t.movie_title
GROUP BY 
    m.title, m.production_year, a.actor_name, m.company_count, t.production_note
HAVING 
    m.production_year BETWEEN 2000 AND 2023
ORDER BY 
    m.production_year DESC, TitleCount DESC;
