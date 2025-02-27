WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS year_rank,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY t.id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    WHERE 
        t.production_year >= 2000 AND t.production_year <= 2023
),
ActorDetails AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS roles_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
),
MoviesWithActors AS (
    SELECT 
        rm.movie_id,
        rm.title,
        COALESCE(ad.actor_name, 'Unknown Actor') AS actor_name,
        rm.production_year,
        rm.year_rank,
        rm.total_cast
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorDetails ad ON rm.movie_id = ad.person_id   -- Just to demonstrate a bizarre join condition
)
SELECT 
    m.title,
    m.production_year,
    m.total_cast,
    STRING_AGG(m.actor_name, ', ') AS actors,
    CASE WHEN m.year_rank = 1 THEN 'First Released' ELSE 'Later Released' END AS release_rank,
    CASE 
        WHEN m.total_cast IS NULL THEN 'No Cast Information'
        WHEN m.total_cast > 5 THEN 'Large Cast' 
        ELSE 'Small Cast' 
    END AS cast_size
FROM 
    MoviesWithActors m
WHERE 
    m.actor_name IS NOT NULL AND 
    (m.production_year % 2 = 0 OR m.production_year IS NULL)  -- Unusual combined predicate
GROUP BY 
    m.title, m.production_year, m.total_cast, m.year_rank
HAVING 
    COUNT(DISTINCT m.actor_name) FILTER (WHERE m.actor_name LIKE '%Smith%') > 0  -- Filter for a specific actor presence
ORDER BY 
    m.production_year DESC
LIMIT 50;

-- Additional subquery to get the most common keywords related to the movie titles
SELECT 
    m.title,
    (SELECT STRING_AGG(k.keyword, ', ') 
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE mk.movie_id = m.movie_id
     GROUP BY mk.movie_id
    ) AS keywords
FROM 
    MoviesWithActors m
WHERE 
    m.total_cast > 3;
