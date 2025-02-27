
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        c.name AS actor_name,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    JOIN 
        title t ON a.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
MovieStats AS (
    SELECT 
        production_year,
        COUNT(movie_title) AS total_movies,
        COUNT(DISTINCT actor_name) AS total_actors
    FROM 
        RankedMovies
    GROUP BY 
        production_year
),
MovieKeywords AS (
    SELECT 
        a.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.movie_id
)
SELECT 
    ms.production_year,
    ms.total_movies,
    ms.total_actors,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    MovieStats ms
LEFT JOIN 
    MovieKeywords mk ON ms.production_year = (SELECT production_year FROM RankedMovies WHERE rank = 1 LIMIT 1)
ORDER BY 
    ms.production_year DESC;
