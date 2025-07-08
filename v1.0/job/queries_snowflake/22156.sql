
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        COUNT(ci.id) AS number_of_roles
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, ak.name, rt.role
),
MoviesWithKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.production_year,
    rt.title AS movie_title,
    ar.actor_name,
    ar.role_name,
    mwk.keywords,
    COALESCE(ar.number_of_roles, 0) AS role_count
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorRoles ar ON rt.title_id = ar.movie_id AND ar.number_of_roles > 1
LEFT JOIN 
    MoviesWithKeywords mwk ON rt.title_id = mwk.movie_id
WHERE 
    (rt.production_year IS NOT NULL)
    AND (rt.title_rank = 1 OR ar.role_name IS NOT NULL)
    AND (rt.production_year BETWEEN 2000 AND 2023 OR ar.actor_name LIKE 'John%')
ORDER BY 
    rt.production_year DESC, 
    rt.title;
