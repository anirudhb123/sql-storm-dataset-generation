WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    GROUP BY 
        a.title, a.production_year
),
ActorStats AS (
    SELECT 
        ak.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
),
FamousMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(ka.movie_id) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword ka ON t.id = ka.movie_id
    LEFT JOIN 
        keyword k ON ka.keyword_id = k.id
    GROUP BY 
        t.title, t.production_year
    HAVING 
        COUNT(ka.movie_id) > 2
)
SELECT 
    rm.title,
    rm.production_year,
    rm.company_count,
    as.actor_name,
    as.movie_title,
    as.movie_rank,
    fm.keyword_count,
    fm.keywords
FROM 
    RankedMovies rm
JOIN 
    ActorStats as ON rm.title = as.movie_title AND rm.production_year = as.production_year
LEFT JOIN 
    FamousMovies fm ON rm.title = fm.title AND rm.production_year = fm.production_year
WHERE 
    rm.rank <= 3
ORDER BY 
    rm.production_year DESC, rm.company_count DESC, as.movie_rank;
