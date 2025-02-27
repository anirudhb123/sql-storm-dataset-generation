WITH ReputableMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT m.company_id) AS total_production_companies,
        AVG(CASE WHEN ci.status_id IS NULL THEN 0 ELSE ci.status_id END) AS average_cast_status
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies m ON t.movie_id = m.movie_id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        t.production_year IS NOT NULL AND t.production_year > 2000
    GROUP BY 
        t.id, t.title
    HAVING 
        COUNT(DISTINCT m.company_id) > 5 AND AVG(COALESCE(ci.status_id, 1)) > 1
),

PopularKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COALESCE(p.info, 'No Info') AS bio_info
    FROM 
        aka_name a
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id AND p.info_type_id = 1
),

PerformanceBench AS (
    SELECT 
        rm.movie_id,
        rm.title,
        ad.actor_id,
        ad.name AS actor_name,
        rk.keyword_list,
        rm.total_production_companies,
        rm.average_cast_status,
        DENSE_RANK() OVER (PARTITION BY rm.movie_id ORDER BY rm.average_cast_status DESC) AS performance_rank
    FROM 
        ReputableMovies rm
    JOIN 
        PopularKeywords rk ON rm.movie_id = rk.movie_id
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        ActorDetails ad ON ci.person_id = ad.actor_id
)

SELECT 
    pb.movie_id,
    pb.title,
    pb.actor_id,
    pb.actor_name,
    pb.keyword_list,
    pb.total_production_companies,
    pb.average_cast_status,
    pb.performance_rank
FROM 
    PerformanceBench pb
WHERE 
    pb.performance_rank = 1 
    AND pb.total_production_companies IS NOT NULL
ORDER BY 
    pb.total_production_companies DESC, 
    pb.average_cast_status ASC;
