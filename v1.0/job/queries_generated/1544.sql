WITH MovieCounts AS (
    SELECT 
        a.title,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(COALESCE(CAST(m.produced_year AS FLOAT), 0)) AS avg_production_year,
        SUM(CASE WHEN co.name IS NOT NULL THEN 1 ELSE 0 END) AS produced_by_companies
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_info mi ON a.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
    GROUP BY 
        a.title
), RankedMovies AS (
    SELECT 
        title,
        actor_count,
        avg_production_year,
        produced_by_companies,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC, avg_production_year ASC) AS movie_rank
    FROM 
        MovieCounts
)
SELECT 
    rm.title,
    rm.actor_count,
    rm.avg_production_year,
    rm.produced_by_companies,
    CASE 
        WHEN rm.produced_by_companies > 0 THEN 'Produced'
        ELSE 'Not Produced'
    END AS production_status
FROM 
    RankedMovies rm
WHERE 
    rm.movie_rank <= 10
ORDER BY 
    rm.actor_count DESC;
