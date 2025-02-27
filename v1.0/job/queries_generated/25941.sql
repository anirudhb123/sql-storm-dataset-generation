WITH RankedTitles AS (
    SELECT 
        at.id AS aka_title_id,
        at.title,
        at.production_year,
        row_number() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MIN(rt.role) AS first_role,
        MAX(rt.role) AS last_role
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.person_role_id = rt.id
    GROUP BY 
        ci.person_id
),
ActorWithTitles AS (
    SELECT 
        ak.name AS actor_name,
        rt.first_role,
        rt.last_role,
        COUNT(DISTINCT rt.movie_id) AS titles_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        ActorRoleCounts arc ON ci.person_id = arc.person_id
    JOIN 
        RankedTitles rt ON ci.movie_id = rt.aka_title_id
    GROUP BY 
        ak.name, rt.first_role, rt.last_role
),
TopActors AS (
    SELECT 
        actor_name, 
        first_role, 
        last_role, 
        titles_count, 
        RANK() OVER (ORDER BY titles_count DESC) AS actor_rank
    FROM 
        ActorWithTitles
)
SELECT 
    ta.actor_name,
    ta.first_role,
    ta.last_role,
    ta.titles_count,
    rt.title,
    rt.production_year
FROM 
    TopActors ta
JOIN 
    RankedTitles rt ON ta.titles_count >= rt.title_rank
WHERE 
    ta.actor_rank <= 10
ORDER BY 
    ta.actor_rank, rt.production_year DESC;
