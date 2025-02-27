WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank_year,
        COUNT(DISTINCT mc.company_id) OVER (PARTITION BY a.id) AS company_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
ActorStatistics AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(m.production_year) AS avg_release_year
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        aka_title m ON c.movie_id = m.id
    GROUP BY 
        ak.name
)
SELECT 
    rm.title,
    rm.production_year,
    rm.kind_id,
    rs.name AS actor_name,
    rs.movie_count,
    rs.avg_release_year,
    CASE 
        WHEN rm.company_count > 5 THEN 'Many' 
        WHEN rm.company_count IS NULL THEN 'Unknown' 
        ELSE 'Few' 
    END AS company_availability
FROM 
    RankedMovies rm
FULL OUTER JOIN 
    ActorStatistics rs ON rm.rank_year = rs.movie_count
WHERE 
    rm.rank_year <= 5 AND 
    (rm.production_year BETWEEN 2000 AND 2023 OR rs.avg_release_year IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rs.movie_count DESC;
