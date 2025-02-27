WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
DetailedInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        cd.company_names,
        cd.total_companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyDetails cd ON rm.movie_id = cd.movie_id
)
SELECT 
    di.production_year,
    COUNT(DISTINCT di.movie_id) AS movie_count,
    AVG(di.actor_count) AS avg_actor_count,
    COUNT(DISTINCT di.company_names) FILTER (WHERE di.company_names IS NOT NULL) AS unique_company_count
FROM 
    DetailedInfo di
WHERE 
    di.actor_count > 5
GROUP BY 
    di.production_year
HAVING 
    COUNT(DISTINCT di.movie_id) > 10
ORDER BY 
    di.production_year DESC;
