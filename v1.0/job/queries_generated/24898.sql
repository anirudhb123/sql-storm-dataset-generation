WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        km.keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY RANDOM()) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword km ON mk.keyword_id = km.id
    WHERE 
        mt.production_year IS NOT NULL
),
ActorRoleInfo AS (
    SELECT 
        ci.movie_id,
        an.name AS actor_name,
        rt.role AS role_name,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, an.name, rt.role
),
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
FinalPerformanceMetrics AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        ARRAY_AGG(DISTINCT ak.actor_name) AS actors,
        ARRAY_AGG(DISTINCT ar.role_name) AS roles,
        ARRAY_AGG(DISTINCT cm.company_name) AS companies,
        MAX(CASE 
            WHEN co.company_count > 5 THEN 'Multiple' 
            ELSE 'Few' 
        END) AS company_count_category
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoleInfo ar ON rm.movie_id = ar.movie_id
    LEFT JOIN 
        CompanyMovieInfo cm ON rm.movie_id = cm.movie_id
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year
)
SELECT 
    *
FROM 
    FinalPerformanceMetrics
WHERE 
    production_year >= 2000
    AND ARRAY_LENGTH(actors, 1) > 3
ORDER BY 
    production_year DESC, movie_title ASC
LIMIT 50;
