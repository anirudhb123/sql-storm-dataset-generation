WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        CASE WHEN rm.actor_count = 0 THEN 'No Actors' ELSE 'With Actors' END AS actor_status
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year BETWEEN 1990 AND 2023
        AND rm.actor_count IS NOT NULL
),
MovieGenres AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    f.title,
    f.production_year,
    f.actor_count,
    f.actor_status,
    COALESCE(mg.keywords, 'No Keywords') AS keywords
FROM 
    FilteredMovies f
LEFT JOIN 
    MovieGenres mg ON f.movie_id = mg.movie_id
WHERE 
    f.actor_count > 5
    AND f.actor_status IS NOT NULL
    AND (f.actor_count < 15 OR f.actor_count IS NULL)
ORDER BY 
    f.production_year DESC, f.actor_count DESC
LIMIT 50;

WITH RecursiveActorCount AS (
    SELECT 
        person_id,
        COUNT(movie_id) AS movie_count 
    FROM 
        cast_info 
    GROUP BY 
        person_id
    HAVING 
        COUNT(movie_id) > 2
),
NewActors AS (
    SELECT 
        a.id AS actor_id,
        n.name AS actor_name
    FROM 
        aka_name a
    JOIN 
        RecursiveActorCount rac ON a.person_id = rac.person_id
    JOIN 
        name n ON a.person_id = n.imdb_id
)
SELECT 
    na.actor_name,
    rac.movie_count,
    COUNT(DISTINCT c.movie_id) AS featured_in,
    STRING_AGG(DISTINCT t.title, ', ') AS titles
FROM 
    NewActors na
JOIN 
    cast_info c ON na.actor_id = c.person_id
LEFT JOIN 
    aka_title t ON c.movie_id = t.id
GROUP BY 
    na.actor_name, rac.movie_count
HAVING 
    featured_in > 10
ORDER BY 
    featured_in DESC;
This SQL query demonstrates various complex constructs including CTEs, aggregations, correlated subqueries, outer joins, and advanced string manipulation. It retrieves data regarding movies from specific periods, keywords associated with those movies, and a count of movie appearances by certain actors while handling NULL values in a meaningful way. It also includes string aggregation to present a list of movie titles for the actors.
