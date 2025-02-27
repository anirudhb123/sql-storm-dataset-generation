
WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS role_count,
        STRING_AGG(DISTINCT r.role ORDER BY r.role) AS roles
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
NullHandledMovies AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        COALESCE(a.name, 'Unknown Actor') AS actor_name
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
)
SELECT 
    n.title,
    n.production_year,
    COALESCE(r.role_count, 0) AS actor_role_count,
    nm.keyword,
    CASE 
        WHEN r.role_count IS NULL THEN 'No roles assigned'
        WHEN r.role_count > 3 THEN 'Major Cast'
        ELSE 'Minor Cast'
    END AS cast_category
FROM 
    RankedMovies n
LEFT JOIN 
    ActorRoles r ON n.title_id = r.movie_id
LEFT JOIN 
    NullHandledMovies nm ON n.title_id = nm.movie_id
WHERE 
    n.title_rank = 1
ORDER BY 
    n.production_year DESC, n.title;
