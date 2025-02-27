WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS title_count
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        a.name, r.role
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    ar.actor_name,
    ar.role_name,
    mwk.keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorRoles ar ON ar.movie_count >= 2
LEFT JOIN 
    MoviesWithKeywords mwk ON rt.title = mwk.movie_id
WHERE 
    rt.rn <= 10
    AND (ar.role_name IS NOT NULL OR mwk.keywords IS NULL)
ORDER BY 
    rt.production_year DESC, rt.title;
