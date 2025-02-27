WITH MovieDetails AS (
    SELECT 
        t.title AS MovieTitle,
        t.production_year AS ProductionYear,
        a.name AS ActorName,
        c.salary AS CastSalary,
        k.keyword AS MovieKeyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        (SELECT person_id, SUM(CASE WHEN role_id IS NOT NULL THEN 10000 ELSE 0 END) AS salary 
         FROM cast_info 
         GROUP BY person_id) c ON ci.person_id = c.person_id
    WHERE 
        t.production_year >= 2000
        AND k.keyword ILIKE '%action%'
),
ActorStats AS (
    SELECT 
        ActorName,
        COUNT(MovieTitle) AS MoviesCount,
        AVG(CastSalary) AS AvgSalary
    FROM 
        MovieDetails
    GROUP BY 
        ActorName
)
SELECT 
    ActorName,
    MoviesCount,
    AvgSalary,
    CASE 
        WHEN MoviesCount >= 5 THEN 'Prolific'
        WHEN MoviesCount BETWEEN 3 AND 4 THEN 'Moderate'
        ELSE 'Emerging' 
    END AS ActorCategory
FROM 
    ActorStats
ORDER BY 
    AvgSalary DESC
LIMIT 10;
