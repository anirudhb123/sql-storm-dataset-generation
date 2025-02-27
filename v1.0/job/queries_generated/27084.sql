WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT k.id) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
    ORDER BY 
        keyword_count DESC,
        actor_count DESC
    LIMIT 10
),
ActorDetails AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        r.role AS role,
        ci.nr_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        ci.movie_id IN (SELECT movie_id FROM RankedMovies)
),
MovieSummaries AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword_count,
        rm.keywords,
        ad.actor_name,
        ad.role,
        ad.nr_order
    FROM 
        RankedMovies rm
    JOIN 
        ActorDetails ad ON rm.movie_id = ad.movie_id
)
SELECT 
    ms.title,
    ms.production_year,
    ms.keywords,
    ARRAY_AGG(DISTINCT ms.actor_name || ' (' || ms.role || ')' ORDER BY ms.nr_order) AS actors
FROM 
    MovieSummaries ms
GROUP BY 
    ms.title, ms.production_year, ms.keywords
ORDER BY 
    ms.production_year DESC;
