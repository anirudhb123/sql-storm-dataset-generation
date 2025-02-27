WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        COUNT(c.id) AS total_cast,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND a.name IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
HighlightedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_name,
        total_cast,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY total_cast DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    movie_id,
    title,
    production_year,
    actor_name,
    total_cast,
    keywords
FROM 
    HighlightedMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year, total_cast DESC;
