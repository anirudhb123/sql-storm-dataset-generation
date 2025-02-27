WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_by_year
    FROM 
        title m
    WHERE 
        m.production_year IS NOT NULL
),

ActorRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS role_name,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, a.name, rt.role
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

JoinedInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.actor_name,
        ar.role_name,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        ar.role_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
)

SELECT 
    ji.title,
    ji.production_year,
    ji.actor_name,
    ji.role_name,
    ji.keywords,
    ji.role_count,
    CASE 
        WHEN ji.role_count IS NULL THEN 'No Roles Assigned'
        WHEN ji.role_count > 5 THEN 'Star Performer'
        ELSE 'Supporting Actor'
    END AS performance_category
FROM 
    JoinedInfo ji
WHERE 
    (ji.production_year BETWEEN 2000 AND 2020 OR ji.production_year IS NULL)
    AND (ji.keywords LIKE '%Action%' OR ji.keywords IS NULL)
ORDER BY 
    ji.production_year DESC, ji.title ASC
LIMIT 100;

