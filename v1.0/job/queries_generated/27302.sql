WITH ActorMovies AS (
    SELECT 
        a.name AS actor_name, 
        t.title AS movie_title, 
        t.production_year,
        r.role AS role_name,
        c.nr_order AS cast_order
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
MovieKeywords AS (
    SELECT 
        t.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
),
ActorKeywordStats AS (
    SELECT 
        am.actor_name, 
        am.movie_title, 
        am.production_year,
        mk.keywords,
        COUNT(mk.movie_id) AS keyword_count
    FROM 
        ActorMovies am
    LEFT JOIN 
        MovieKeywords mk ON am.movie_title = mk.movie_title
    GROUP BY 
        am.actor_name, am.movie_title, am.production_year, mk.keywords
)
SELECT 
    actor_name, 
    movie_title, 
    production_year, 
    keywords,
    keyword_count
FROM 
    ActorKeywordStats
ORDER BY 
    actor_name, production_year DESC, keyword_count DESC;

This query constructs a multi-level Common Table Expression (CTE) that aggregates actor movie associations, retrieves keywords for each movie, and produces a final result set showing each actor's movies with the corresponding keywords and keyword counts. It filters for movies produced between 2000 and 2023 and orders the results by actor name, production year, and keyword count, providing a detailed overview for benchmarking string processing.
