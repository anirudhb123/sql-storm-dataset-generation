WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY t.id) AS total_cast,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year >= 2000 -- Filter only movies after the year 2000
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
ActorStats AS (
    SELECT 
        actor_name,
        COUNT(*) AS movies_participated,
        MIN(production_year) AS first_movie_year,
        MAX(production_year) AS last_movie_year
    FROM 
        RankedMovies
    GROUP BY 
        actor_name
),
MostActiveActors AS (
    SELECT 
        actor_name,
        movies_participated,
        first_movie_year,
        last_movie_year,
        RANK() OVER (ORDER BY movies_participated DESC) AS active_rank
    FROM 
        ActorStats
)
SELECT 
    maa.actor_name,
    maa.movies_participated,
    maa.first_movie_year,
    maa.last_movie_year,
    rm.movie_title,
    rm.production_year,
    rm.total_cast,
    rm.keywords
FROM 
    MostActiveActors maa
JOIN 
    RankedMovies rm ON maa.actor_name = rm.actor_name
WHERE 
    maa.active_rank <= 10 -- Fetch top 10 most active actors
ORDER BY 
    maa.movies_participated DESC, rm.production_year DESC;
