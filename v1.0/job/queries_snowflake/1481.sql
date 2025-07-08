WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(ci.role_id) AS role_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(ci.role_id) > 5
),
MoviesWithKeywords AS (
    SELECT 
        m.title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.title
    HAVING 
        COUNT(mk.keyword_id) > 2
)
SELECT 
    rt.title,
    rt.production_year,
    ar.actor_name,
    ar.role_count,
    mwk.keyword_count
FROM 
    RankedTitles rt
JOIN 
    ActorRoles ar ON rt.title = ar.actor_name
LEFT JOIN 
    MoviesWithKeywords mwk ON rt.title = mwk.title
WHERE 
    rt.title_rank <= 10
ORDER BY 
    rt.production_year DESC, 
    mwk.keyword_count DESC, 
    ar.role_count DESC
LIMIT 50;
