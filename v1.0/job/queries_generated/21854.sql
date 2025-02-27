WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rnk
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

AggregateCast AS (
    SELECT 
        c.movie_id,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(a.name, ', ') AS actors
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        c.movie_id
),

KeywordMovies AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)

SELECT 
    r.title,
    r.production_year,
    r.kind_id,
    COALESCE(ac.cast_count, 0) AS cast_count,
    COALESCE(ac.actors, 'No actors') AS actors,
    COALESCE(km.keywords, 'No keywords') AS keywords
FROM 
    RankedMovies r
LEFT JOIN 
    AggregateCast ac ON r.id = ac.movie_id
LEFT JOIN 
    KeywordMovies km ON r.id = km.movie_id
WHERE 
    r.rnk <= 5 -- Get top 5 movies per kind
    AND r.production_year >= 1950 -- Post-war cinema
ORDER BY 
    r.kind_id, r.production_year DESC;

-- Additional filtering and note, omitting NULL casts or keywords for peculiar edge cases
WITH TopGenres AS (
    SELECT 
        k.kind,
        COUNT(DISTINCT r.id) AS genre_count
    FROM 
        aka_title a
    LEFT JOIN 
        kind_type k ON a.kind_id = k.id
    WHERE 
        k.kind IS NOT NULL
    GROUP BY 
        k.kind
    HAVING 
        COUNT(DISTINCT a.id) > 1 -- Only genres with more than one movie
)

SELECT 
    g.kind,
    g.genre_count,
    COALESCE(SUM(r.cast_count), 0) AS total_cast_count
FROM 
    TopGenres g
LEFT JOIN 
    AggregateCast r ON g.kind = (SELECT k.kind FROM kind_type k WHERE k.id = r.kind_id)
GROUP BY 
    g.kind, g.genre_count
HAVING 
    AVG(r.cast_count) > 2 -- Average cast count per genre greater than 2
ORDER BY 
    total_cast_count DESC;

-- This query demonstrates the chaining of complexities, leveraging CTEs to isolate calculations, 
-- while also showcasing outer joins, aggregates and filtering based on collective conditions.
