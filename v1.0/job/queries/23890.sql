WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn,
        COUNT(*) OVER (PARTITION BY m.production_year) AS movie_count
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL AND
        m.title NOT LIKE '%Untitled%'
),
ActorRoleCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MAX(CASE WHEN r.role = 'Director' THEN 1 ELSE 0 END) AS is_directed,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FinalBenchmark AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.actor_count,
        ar.actors,
        co.company_count,
        co.companies,
        CASE 
            WHEN ar.is_directed = 1 THEN 'Directed'
            ELSE 'Not Directed'
        END AS directorship_status,
        CASE 
            WHEN co.company_count IS NULL THEN 'No companies listed'
            ELSE 'Companies Exist'
        END AS company_status
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoleCounts ar ON rm.movie_id = ar.movie_id
    LEFT JOIN 
        CompanyInfo co ON rm.movie_id = co.movie_id
)
SELECT 
    title,
    production_year,
    actor_count,
    actors,
    company_count,
    companies,
    directorship_status,
    company_status,
    CASE 
        WHEN actor_count > 5 THEN 'Popular Actor Cast'
        WHEN actor_count IS NULL THEN 'No Cast Information'
        ELSE 'Less Known Cast'
    END AS cast_description
FROM 
    FinalBenchmark
WHERE 
    production_year IS NOT NULL 
    AND (company_status IS NOT NULL OR directorship_status = 'Directed')
ORDER BY 
    production_year, title;
