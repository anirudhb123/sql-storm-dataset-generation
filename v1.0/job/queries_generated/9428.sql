WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
),
ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    GROUP BY 
        a.id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.company_count,
    rm.keywords,
    ad.actor_name,
    ad.movie_count,
    ad.movies
FROM 
    RankedMovies rm
JOIN 
    ActorDetails ad ON rm.title = ANY(ad.movies) 
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, 
    ad.movie_count DESC
LIMIT 10;
