
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
HighActorMovies AS (
    SELECT 
        rm.title, 
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieGenreKeywords AS (
    SELECT 
        m.id AS movie_id, 
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    ham.title AS top_movies, 
    ham.production_year, 
    COALESCE(mgk.keywords, 'No Keywords') AS keywords
FROM 
    HighActorMovies ham
LEFT JOIN 
    MovieGenreKeywords mgk ON mgk.movie_id = (SELECT MAX(m.id) FROM aka_title m JOIN movie_keyword mk ON m.id = mk.movie_id WHERE m.production_year = ham.production_year)
ORDER BY 
    ham.production_year DESC, ham.title;
