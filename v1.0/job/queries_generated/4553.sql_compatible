
WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY RANDOM()) as rank
    FROM 
        aka_title at
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        ct.kind AS role_type,
        at.title AS movie_title,
        at.production_year
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        ak.name IS NOT NULL AND ct.kind IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        mt.title AS movie_title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.title
)
SELECT 
    ar.actor_name,
    ar.role_type,
    ar.movie_title,
    mwk.keywords,
    ar.production_year
FROM 
    ActorRoles ar
LEFT JOIN 
    MoviesWithKeywords mwk ON ar.movie_title = mwk.movie_title
WHERE 
    (ar.production_year > 2000 AND mwk.keywords IS NOT NULL)
    OR (ar.role_type LIKE '%lead%')
ORDER BY 
    ar.actor_name, ar.production_year DESC
LIMIT 50;
