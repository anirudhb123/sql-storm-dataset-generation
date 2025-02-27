WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
),
ActorStats AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movies_count,
        AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles_with_note
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
CompanyMovieInfo AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    as.actor_name,
    as.movies_count,
    as.avg_roles_with_note,
    cm.companies,
    cm.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorStats as ON rm.year_rank = 1 AND rm.production_year IN (
        SELECT 
            DISTINCT production_year 
        FROM 
            aka_title
        WHERE 
            production_year BETWEEN 2000 AND 2023
    )
LEFT JOIN 
    CompanyMovieInfo cm ON rm.movie_id = cm.movie_id
WHERE 
    cm.companies IS NOT NULL
ORDER BY 
    rm.production_year DESC, as.movies_count DESC;
