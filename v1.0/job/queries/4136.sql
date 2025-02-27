WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastInfoWithNulls AS (
    SELECT 
        c.movie_id,
        COUNT(CASE WHEN c.person_role_id IS NULL THEN 1 END) AS null_roles_count,
        SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS ordered_cast_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cs.company_count,
    cs.company_names,
    cwn.null_roles_count,
    cwn.ordered_cast_count,
    CASE 
        WHEN cs.company_count > 0 THEN 'Has Companies' 
        ELSE 'No Companies' 
    END AS company_status
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyStats cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    CastInfoWithNulls cwn ON rm.movie_id = cwn.movie_id
WHERE 
    (rm.title_rank = 1 OR rm.title ILIKE '%Avengers%')
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
