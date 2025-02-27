WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
), 
ActorMovies AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        title_rank,
        COUNT(*) OVER (PARTITION BY actor_name) AS total_movies
    FROM 
        RankedTitles
), 
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id, m.title
)
SELECT 
    a.actor_name,
    a.movie_title,
    a.production_year,
    a.total_movies,
    COALESCE(m.keywords, 'No keywords available') AS keywords,
    CASE 
        WHEN a.title_rank = 1 THEN 'Latest'
        ELSE 'Earlier'
    END AS title_status
FROM 
    ActorMovies a
LEFT JOIN 
    MoviesWithKeywords m ON a.movie_title = m.title
WHERE 
    a.total_movies > 3
ORDER BY 
    a.actor_name, a.production_year DESC
LIMIT 50;
