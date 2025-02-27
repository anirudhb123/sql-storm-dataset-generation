WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_with_most_actors
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_actors
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
), 
MoviesWithGenres AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(k.keyword, ', ') AS genres
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        m.id, m.title
), 
CompleteInfo AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        a.total_actors,
        m.genres,
        COALESCE(r.rank_with_most_actors, 9999) AS rank -- Using 9999 as a high default for movies with no actors
    FROM 
        RankedMovies r
    LEFT JOIN 
        ActorCounts a ON r.movie_id = a.movie_id
    LEFT JOIN 
        MoviesWithGenres m ON r.movie_id = m.movie_id
)

SELECT 
    ci.title,
    ci.production_year,
    ci.total_actors,
    ci.genres,
    CASE 
        WHEN ci.rank < 4 THEN 'Top Movie of the Year'
        WHEN ci.total_actors IS NULL THEN 'No Actors Listed'
        ELSE 'Watch Later'
    END AS watch_priority
FROM 
    CompleteInfo ci
WHERE 
    ci.production_year BETWEEN 2000 AND 2020
    AND (ci.genres ILIKE '%comedy%' OR ci.genres IS NULL) 
ORDER BY 
    ci.rank, ci.total_actors DESC NULLS LAST;

This query performs a series of operations using Common Table Expressions (CTEs) to rank movies based on the total number of actors per production year, alongside their genres. It captures a wide spectrum of SQL features including aggregate functions, window functions, outer joins, a concatenation of strings, conditional expressions, and complex predicates to generate a watch list of movies deemed interesting based on actor count and genre relevance, while also handling NULL logic elegantly.
