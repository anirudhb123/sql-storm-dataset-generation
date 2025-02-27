WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordMovies AS (
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
),
CompleteMovieInfo AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_count,
        rm.actor_names,
        km.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        KeywordMovies km ON rm.movie_title = (SELECT title FROM aka_title WHERE id = km.movie_id)
    WHERE 
        rm.actor_count > 10
)
SELECT 
    movie_title,
    production_year,
    actor_count,
    actor_names,
    keywords
FROM 
    CompleteMovieInfo
ORDER BY 
    production_year DESC, actor_count DESC;
