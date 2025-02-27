WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(*) OVER (PARTITION BY c.movie_id, r.role) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        role_type r ON r.id = c.role_id
    WHERE 
        c.note IS NULL
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON c.id = mc.company_id
    WHERE 
        c.country_code IS NOT NULL AND c.country_code <> ''
    GROUP BY 
        mc.movie_id
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ar.actor_name,
    ar.role_name,
    mc.company_count,
    kc.keyword_count,
    (CASE 
        WHEN mc.company_count IS NULL THEN 'No Companies'
        WHEN kc.keyword_count IS NULL THEN 'No Keywords'
        ELSE 'Has Companies & Keywords'
    END) AS status,
    (SELECT 
        COUNT(*) 
     FROM 
        complete_cast cc 
     WHERE 
        cc.movie_id = rm.movie_id
    ) AS total_cast
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON ar.movie_id = rm.movie_id
LEFT JOIN 
    MovieCompanies mc ON mc.movie_id = rm.movie_id
LEFT JOIN 
    KeywordCount kc ON kc.movie_id = rm.movie_id
WHERE 
    rm.rn = 1
    AND (ar.role_name IS NOT NULL OR mc.company_count IS NULL)
ORDER BY 
    rm.production_year DESC, rm.title;
