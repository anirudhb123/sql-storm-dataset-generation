WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
HighestRankedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        cd.company_names,
        cd.company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyDetails cd ON rm.movie_id = cd.movie_id
    WHERE 
        rm.rank <= 10
)
SELECT 
    h.title,
    h.production_year,
    h.actor_count,
    COALESCE(h.company_names, 'No Companies') AS company_names,
    COALESCE(h.company_count, 0) AS number_of_companies
FROM 
    HighestRankedMovies h
WHERE 
    h.actor_count > 5
ORDER BY 
    h.production_year DESC, h.actor_count DESC
LIMIT 20;
