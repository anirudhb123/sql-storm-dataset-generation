WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
ActorRoleCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COALESCE(STRING_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')'), ', '), 'No Cast') AS cast_details
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS num_actors,
    COALESCE(ac.cast_details, 'No Cast') AS cast_details,
    COALESCE(mk.keyword_count, 0) AS num_keywords,
    COALESCE(cc.company_count, 0) AS num_companies
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoleCount ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    CompanyCounts cc ON rm.movie_id = cc.movie_id
WHERE 
    (rm.production_year BETWEEN 2000 AND 2023)
    AND (ac.actor_count > 2 OR mk.keyword_count > 5)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
