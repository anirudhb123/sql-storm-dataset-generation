WITH RecursiveActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY m.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title m ON c.movie_id = m.movie_id
    WHERE 
        a.name IS NOT NULL
    AND 
        m.production_year IS NOT NULL
), 
TopActors AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(movie_id) AS movie_count
    FROM 
        RecursiveActorMovies
    WHERE 
        rn <= 5
    GROUP BY 
        actor_id, actor_name
    HAVING 
        COUNT(movie_id) >= 3
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
),
ActorStats AS (
    SELECT 
        a.actor_name,
        COALESCE(m.keyword_count, 0) AS keyword_count,
        COALESCE(t.movie_count, 0) AS top_movie_count
    FROM 
        TopActors t
    FULL OUTER JOIN RecursiveActorMovies a ON t.actor_name = a.actor_name
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(*) AS keyword_count
        FROM 
            movie_keyword
        GROUP BY 
            movie_id
    ) m ON m.movie_id = a.movie_id
)
SELECT 
    as.actor_name,
    as.keyword_count,
    as.top_movie_count,
    COALESCE(films.movie_title, 'No Movies Found') AS movie_title,
    CASE 
        WHEN as.keyword_count > 0 AND as.top_movie_count > 0 THEN 'Active'
        WHEN as.keyword_count = 0 THEN 'Inactive'
        WHEN as.top_movie_count = 0 THEN 'Emerging'
        ELSE 'Unknown'
    END AS status,
    SUBSTRING(as.actor_name FROM 1 FOR 10) || '...' AS short_name
FROM 
    ActorStats as 
LEFT JOIN 
    (SELECT DISTINCT ON (m.id)
        m.title AS movie_title,
        m.production_year
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2020) films 
ON 
    films.movie_title = as.actor_name
ORDER BY 
    as.top_movie_count DESC, as.keyword_count DESC NULLS LAST
LIMIT 50;
