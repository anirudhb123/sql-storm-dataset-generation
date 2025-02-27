WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COALESCE(SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS actor_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rnk
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info c ON mt.id = c.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopActors AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name ak
    INNER JOIN 
        cast_info c ON ak.person_id = c.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FinalResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count,
        ta.movie_count,
        cm.company_name,
        cm.company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        TopActors ta ON rm.actor_count = ta.movie_count
    LEFT JOIN 
        CompanyMovies cm ON rm.title = cm.movie_name
)
SELECT 
    *,
    (CASE 
        WHEN actor_count > 10 THEN 'High'
        WHEN actor_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END) AS actor_rank,
    CONCAT('Movie: ', title, ', Year: ', production_year) AS movie_details
FROM 
    FinalResults
WHERE 
    production_year IS NOT NULL
ORDER BY 
    production_year DESC, actor_count DESC;
