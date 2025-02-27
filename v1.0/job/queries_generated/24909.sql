WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
),
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS actor_role,
        COUNT(*) OVER (PARTITION BY ci.movie_id, a.id ORDER BY rt.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        RANK() OVER (PARTITION BY mk.movie_id ORDER BY COUNT(mk.id) DESC) AS keyword_rank
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
)
SELECT 
    rm.movie_title,
    rm.production_year,
    cc.company_count,
    ar.actor_name,
    ar.actor_role,
    ar.role_count,
    pk.keyword
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovieCounts cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id AND ar.role_count > 1
LEFT JOIN 
    PopularKeywords pk ON rm.movie_id = pk.movie_id AND pk.keyword_rank <= 3
WHERE 
    rm.title_rank <= 5 
    AND coalesce(rm.production_year, 1900) BETWEEN 1980 AND 2023
    AND (pk.keyword IS NOT NULL OR cc.company_count BETWEEN 1 AND 5)
ORDER BY 
    rm.production_year DESC,
    rm.movie_title ASC,
    ar.actor_name DESC;
