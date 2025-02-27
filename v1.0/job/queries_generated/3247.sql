WITH RankedMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND t.production_year IS NOT NULL
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT c.company_id) AS company_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON mc.movie_id = mk.movie_id
    JOIN 
        complete_cast cc ON cc.movie_id = mk.movie_id
    JOIN 
        title m ON m.id = mk.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.movie_id
),
ActorStatistics AS (
    SELECT 
        actor_id,
        COUNT(DISTINCT movie_title) AS total_movies,
        SUM(CASE WHEN year_rank = 1 THEN 1 ELSE 0 END) AS latest_movies
    FROM 
        RankedMovies
    GROUP BY 
        actor_id
)
SELECT 
    a.actor_id,
    a.actor_name,
    m.movie_title,
    m.production_year,
    ms.total_movies,
    ms.latest_movies,
    COALESCE(mi.keywords, 'No keywords') AS keywords,
    COALESCE(mi.company_count, 0) AS company_count
FROM 
    RankedMovies a
LEFT JOIN 
    MovieInfo mi ON a.id = mi.movie_id
JOIN 
    ActorStatistics ms ON a.actor_id = ms.actor_id
WHERE 
    ms.total_movies > 5
ORDER BY 
    a.actor_name, a.production_year DESC
LIMIT 100;
