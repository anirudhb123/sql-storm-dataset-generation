WITH RankedMovies AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) as year_rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
ActorMovies AS (
    SELECT 
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        MAX(t.production_year) AS last_movie_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
KeywordStats AS (
    SELECT 
        k.keyword,
        COUNT(mk.movie_id) AS movie_count
    FROM 
        keyword k
    JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY 
        k.id, k.keyword
    ORDER BY 
        movie_count DESC
    LIMIT 10
)
SELECT 
    rm.title,
    rm.production_year,
    am.name AS actor_name,
    am.movie_count AS actor_movie_count,
    ks.keyword AS top_keyword,
    ks.movie_count AS keyword_movie_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorMovies am ON rm.year_rank = 1
LEFT JOIN 
    KeywordStats ks ON rm.title LIKE '%' || ks.keyword || '%'
WHERE 
    rm.company_count > 2
ORDER BY 
    rm.production_year DESC, am.movie_count DESC, ks.movie_count DESC
LIMIT 50;
