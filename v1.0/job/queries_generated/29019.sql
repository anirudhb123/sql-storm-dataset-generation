WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        a.id AS actor_id,
        k.keyword AS movie_keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
),
FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        ARRAY_AGG(DISTINCT actor_name) AS cast,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM 
        MovieDetails
    GROUP BY 
        movie_title, production_year
),
RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY production_year DESC) AS rank
    FROM 
        FilteredMovies
)
SELECT 
    movie_title,
    production_year,
    cast,
    keywords
FROM 
    RankedMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year DESC, movie_title;
