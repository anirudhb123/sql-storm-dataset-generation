WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        ct.kind AS role_type,
        COUNT(ci.id) AS movies_played
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        ak.name, ct.kind
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mkw
    JOIN 
        keyword k ON mkw.keyword_id = k.id
    JOIN 
        aka_title m ON m.id = mkw.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ar.actor_name,
    ar.role_type,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.title_id = ar.movies_played
LEFT JOIN 
    MovieKeywords mk ON rm.title_id = mk.movie_id
WHERE 
    rm.rn <= 3
ORDER BY 
    rm.production_year DESC, rm.title ASC;
