WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        c.name AS actor_name,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER(PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
        AND k.keyword IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        movie_title, 
        actor_name, 
        movie_keyword
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    movie_title,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
FROM 
    FilteredMovies
GROUP BY 
    movie_title
ORDER BY 
    movie_title;

