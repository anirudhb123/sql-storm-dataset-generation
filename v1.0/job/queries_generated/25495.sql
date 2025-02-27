WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year >= 2000 -- Analyze movies produced since 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year,
        actor_count,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        actor_count > 5 -- Only consider movies with more than 5 actors
),
MoviesWithKeywords AS (
    SELECT 
        tm.title,
        tm.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    mwk.title,
    mwk.production_year,
    mwk.keywords,
    COUNT(movies.movie_id) AS linked_movies_count
FROM 
    MoviesWithKeywords mwk
LEFT JOIN 
    movie_link ml ON mwk.movie_id = ml.movie_id
LEFT JOIN 
    aka_title movies ON ml.linked_movie_id = movies.id
GROUP BY 
    mwk.title, mwk.production_year, mwk.keywords
ORDER BY 
    mwk.production_year DESC, linked_movies_count DESC
LIMIT 10; -- Limit to the top 10 results
