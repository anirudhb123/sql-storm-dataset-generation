WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), MovieGenres AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
), ActorStats AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(CASE WHEN c.person_role_id = (SELECT id FROM role_type WHERE role = 'Actor') THEN 1 ELSE 0 END) AS avg_actor_role
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
), MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count,
        MAX(co.name) AS example_company
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    CASE 
        WHEN mcd.company_count > 5 THEN 'High Budget'
        ELSE 'Low Budget'
    END AS budget_category,
    ms.genres,
    as.actor_count,
    as.avg_actor_role
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieGenres ms ON rm.title = ms.title
LEFT JOIN 
    ActorStats as ON rm.id = as.movie_id
LEFT JOIN 
    MovieCompanyDetails mcd ON rm.id = mcd.movie_id
WHERE 
    rm.year_rank <= 10
    AND (mcd.company_count IS NULL OR mcd.company_count >= 1)
ORDER BY 
    rm.production_year DESC, rm.title
LIMIT 50;
