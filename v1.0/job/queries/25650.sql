WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COALESCE(cc.kind, 'Unknown') AS company_type,
        COUNT(DISTINCT a.name) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_type cc ON mc.company_type_id = cc.id
    LEFT JOIN complete_cast cc2 ON t.id = cc2.movie_id
    LEFT JOIN cast_info ci ON cc2.subject_id = ci.id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, cc.kind
),
AverageActorCount AS (
    SELECT 
        AVG(actor_count) AS avg_actor_count,
        production_year
    FROM 
        MovieDetails
    GROUP BY 
        production_year
),
YearlyComparison AS (
    SELECT 
        mv.production_year,
        mv.movie_title,
        mv.keywords,
        mv.company_type,
        mv.actor_count,
        ac.avg_actor_count,
        CASE 
            WHEN mv.actor_count > ac.avg_actor_count THEN 'Above Average'
            WHEN mv.actor_count < ac.avg_actor_count THEN 'Below Average'
            ELSE 'Average'
        END AS actor_count_comparison
    FROM 
        MovieDetails mv
    LEFT JOIN AverageActorCount ac ON mv.production_year = ac.production_year
)
SELECT 
    production_year,
    COUNT(*) AS total_movies,
    COUNT(CASE WHEN actor_count_comparison = 'Above Average' THEN 1 END) AS above_avg_count,
    COUNT(CASE WHEN actor_count_comparison = 'Below Average' THEN 1 END) AS below_avg_count,
    COUNT(CASE WHEN actor_count_comparison = 'Average' THEN 1 END) AS average_count
FROM 
    YearlyComparison
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
