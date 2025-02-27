WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS movie_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
ActorsInMultipleMovies AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count
    FROM 
        RankedMovies
    GROUP BY 
        actor_name
    HAVING 
        COUNT(DISTINCT movie_title) > 5
),
MoviesWithKeywords AS (
    SELECT 
        t.title,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%action%' OR k.keyword LIKE '%drama%'
)
SELECT 
    r.movie_title,
    r.production_year,
    a.actor_name,
    k.keyword
FROM 
    RankedMovies r
JOIN 
    ActorsInMultipleMovies a ON r.actor_name = a.actor_name
JOIN 
    MoviesWithKeywords k ON r.movie_title = k.title
ORDER BY 
    r.production_year DESC, 
    r.movie_rank;
