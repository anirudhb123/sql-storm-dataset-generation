WITH ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.role_id) AS roles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        a.name LIKE '%John%' -- Filtering actors with 'John' in their name
    GROUP BY 
        a.id, a.name, t.title, t.production_year
),

MovieKeywords AS (
    SELECT 
        t.id AS movie_id,
        k.keyword AS keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 -- Considering movies from year 2000 onwards
),

ActorKeywordStats AS (
    SELECT 
        am.actor_id,
        am.actor_name,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        COUNT(DISTINCT am.movie_title) AS movie_count,
        MIN(am.production_year) AS first_movie_year,
        MAX(am.production_year) AS last_movie_year
    FROM 
        ActorMovies am
    LEFT JOIN 
        MovieKeywords mk ON am.movie_title = mk.keyword
    GROUP BY 
        am.actor_id, am.actor_name
)

SELECT 
    a.actor_name,
    a.movie_count,
    a.keyword_count,
    a.first_movie_year,
    a.last_movie_year
FROM 
    ActorKeywordStats a
WHERE 
    a.keyword_count > 5 -- Actors associated with more than 5 distinct keywords
ORDER BY 
    a.movie_count DESC, 
    a.keyword_count DESC; 
