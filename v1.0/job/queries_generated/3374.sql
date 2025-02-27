WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_num
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorStats AS (
    SELECT 
        DISTINCT ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        AVG(m.production_year) AS average_year
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.id
    GROUP BY 
        ak.name
),
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(as.actor_name, 'Unknown Actor') AS leading_actor,
    COALESCE(as.movies_count, 0) AS total_movies_with_actor,
    COALESCE(as.average_year, 0) AS average_production_year,
    cm.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorStats as ON as.average_year = rm.production_year
LEFT JOIN 
    CompanyMovieInfo cm ON cm.movie_id = rm.movie_id
WHERE 
    rm.rank_num <= 5
ORDER BY 
    rm.production_year DESC, rm.title;
