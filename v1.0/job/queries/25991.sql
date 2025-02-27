WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY k.keyword ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
MostRecentTitles AS (
    SELECT 
        title_id,
        title,
        production_year,
        keyword
    FROM 
        RankedTitles
    WHERE 
        rank = 1
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
)
SELECT 
    mrt.title,
    mrt.production_year,
    mrt.keyword,
    ar.actor_name,
    ar.role
FROM 
    MostRecentTitles mrt
JOIN 
    ActorRoles ar ON mrt.title_id = ar.movie_id
ORDER BY 
    mrt.production_year DESC, 
    mrt.title;