WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COALESCE(k.keyword, 'No Keyword') AS keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
ActorRoles AS (
    SELECT 
        a.name AS actor_name, 
        r.role AS role_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        a.name, r.role
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
CompanyStock AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        MAX(CASE WHEN ct.kind = 'Production' THEN 1 ELSE 0 END) AS has_production
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        complete_cast m ON mc.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
),
FinalMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        a.actor_name,
        ar.role_name,
        cs.company_count,
        CASE 
            WHEN cs.has_production = 1 THEN 'Produced' 
            ELSE 'Not Produced' 
        END AS production_status
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON ar.movie_count > 5 
    LEFT JOIN 
        CompanyStock cs ON rm.movies_id = cs.movie_id
    WHERE 
        rm.year_rank <= 3
)
SELECT 
    f.movie_title,
    f.production_year,
    f.actor_name,
    f.role_name,
    f.company_count,
    f.production_status
FROM 
    FinalMovies f
WHERE 
    (f.production_year IS NOT NULL)
    AND (f.company_count IS NOT NULL OR f.actor_name IS NOT NULL)
ORDER BY 
    f.production_year DESC, 
    f.movie_title ASC;
