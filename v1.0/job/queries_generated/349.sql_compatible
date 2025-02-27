
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
ActorMovies AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieSummary AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cc.company_count, 0) AS company_count,
        COALESCE(am.actor_count, 0) AS actor_count,
        rm.year_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyCounts cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        ActorMovies am ON rm.movie_id = am.movie_id
)
SELECT 
    ms.title,
    ms.production_year,
    ms.company_count,
    ms.actor_count,
    CASE 
        WHEN ms.actor_count > 10 THEN 'Popular'
        WHEN ms.actor_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Less Popular'
    END AS popularity,
    (SELECT 
        STRING_AGG(k.keyword, ', ')
     FROM 
        movie_keyword mk
     JOIN 
        keyword k ON mk.keyword_id = k.id
     WHERE 
        mk.movie_id = ms.movie_id) AS keywords
FROM 
    MovieSummary ms
WHERE 
    ms.year_rank <= 5
ORDER BY 
    ms.production_year DESC,
    ms.actor_count DESC
LIMIT 10;
