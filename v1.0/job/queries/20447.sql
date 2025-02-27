WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        t.id AS movie_id
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.name AS actor_name,
        c.movie_id,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
),
UniqueKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COALESCE(COUNT(com.name), 0) AS company_count,
        MAX(com.country_code) AS country
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name com ON mc.company_id = com.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ar.actor_name,
    ar.role_name,
    uk.keywords,
    mc.company_count,
    mc.country
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id 
    AND ar.role_order = 1  
LEFT JOIN 
    UniqueKeywords uk ON rm.movie_id = uk.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE 
    (rm.production_year >= 2000 OR rm.production_year IS NULL)  
ORDER BY 
    rm.production_year DESC, 
    mc.company_count DESC, 
    ar.actor_name;