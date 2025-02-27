
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY rt.id) AS rn
    FROM 
        title t
    LEFT JOIN 
        role_type rt ON rt.id IN (SELECT role_id FROM cast_info ci WHERE ci.movie_id = t.id)
    WHERE 
        t.production_year IS NOT NULL
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON c.id = mc.company_id
    WHERE 
        mc.note IS NULL OR mc.note != 'secondary'
    GROUP BY 
        mc.movie_id
),
CastInfoWithNames AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ci.nr_order,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
),
FinalResults AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        c.company_count,
        ci.actor_name,
        ci.actor_rank
    FROM 
        RankedTitles rt
    JOIN 
        CompanyCounts c ON c.movie_id = rt.title_id
    LEFT JOIN 
        CastInfoWithNames ci ON ci.movie_id = rt.title_id
)
SELECT *
FROM 
    FinalResults 
WHERE 
    actor_rank < 4 AND production_year >= 2000
ORDER BY 
    company_count DESC, production_year ASC
LIMIT 10;
