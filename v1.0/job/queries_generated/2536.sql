WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorStatistics AS (
    SELECT
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(COALESCE(DATEDIFF(NOW(), mi.info), 0)) AS avg_years_since_release
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_info mi ON ci.movie_id = mi.movie_id AND mi.info_type_id = 
            (SELECT id FROM info_type WHERE info = 'release_year')
    GROUP BY 
        a.name
)
SELECT 
    rm.title,
    rm.production_year,
    as.name AS actor_name,
    as.movie_count,
    as.avg_years_since_release,
    (SELECT COUNT(*) 
     FROM movie_companies mc 
     WHERE mc.movie_id = rm.id AND mc.company_type_id = 
         (SELECT id FROM company_type WHERE kind = 'Distributor')) AS distributor_count,
    STRING_AGG(k.keyword, ', ') AS keywords
FROM 
    RankedMovies rm
JOIN 
    ActorStatistics as ON rm.title_rank <= 5
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = rm.id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    rm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    rm.production_year DESC, 
    as.movie_count DESC, 
    rm.title;
