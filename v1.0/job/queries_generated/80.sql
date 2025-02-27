WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        c.kind AS movie_type,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        kind_type c ON a.kind_id = c.id
    WHERE 
        a.production_year IS NOT NULL
),
ActorStatistics AS (
    SELECT 
        ka.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS average_notes_present
    FROM 
        cast_info ci
    JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    GROUP BY 
        ka.name
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_type_id) AS company_type_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        as.actor_name,
        ci.company_names,
        ci.company_type_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorStatistics as ON rm.year_rank <= 10
    LEFT JOIN 
        CompanyInfo ci ON rm.title = ci.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_name,
    COALESCE(tm.company_names, 'No Companies') AS company_names,
    COALESCE(tm.company_type_count, 0) AS company_type_count
FROM 
    TopMovies tm
WHERE 
    tm.production_year = (
        SELECT MAX(production_year) 
        FROM RankedMovies
    )
ORDER BY 
    tm.company_type_count DESC, tm.actor_name;
