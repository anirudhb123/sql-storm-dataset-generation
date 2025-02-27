WITH MovieInfo AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        t.title, t.production_year
),

ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
),

RankedMovies AS (
    SELECT 
        mi.title,
        mi.production_year,
        mi.company_count,
        mi.keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mi.production_year ORDER BY mi.company_count DESC) AS rn
    FROM 
        MovieInfo mi
)

SELECT 
    rm.title,
    rm.production_year,
    rm.company_count,
    rm.keyword_count,
    ai.actor_name,
    ai.movies_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorInfo ai ON rm.rn = 1
WHERE 
    rm.production_year IN (SELECT production_year FROM RankedMovies WHERE company_count > 5)
ORDER BY 
    rm.production_year DESC, 
    rm.company_count DESC;
