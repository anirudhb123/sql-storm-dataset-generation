WITH RECURSIVE ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
), MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count,
        SUM(CASE WHEN m.production_year < 2000 THEN 1 ELSE 0 END) AS pre_2000_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.movie_id
), ActorSummary AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(movie_id) AS total_movies,
        AVG(movie_rank) AS average_movie_rank
    FROM 
        ActorMovies
    WHERE 
        movie_rank <= 5
    GROUP BY 
        actor_id, actor_name
)
SELECT 
    a.actor_id,
    a.actor_name,
    a.total_movies,
    COALESCE(m.movie_id, 0) AS movie_id,
    COALESCE(m.keywords, 'No Keywords') AS keywords,
    COALESCE(m.company_count, 0) AS company_count,
    COALESCE(m.pre_2000_count, 0) AS pre_2000_count
FROM 
    ActorSummary a
LEFT JOIN 
    MovieInfo m ON a.total_movies > 1 AND a.total_movies < 10
WHERE 
    a.average_movie_rank < 3  -- Actors with top rankings
ORDER BY 
    a.total_movies DESC, 
    a.actor_name;
