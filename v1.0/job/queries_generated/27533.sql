WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS lead_actors
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year
), 
HighCastMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        lead_actors,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        total_cast > 5
),
MovieDetails AS (
    SELECT 
        h.movie_id,
        h.title,
        h.production_year,
        h.total_cast,
        h.lead_actors,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        HighCastMovies h
    LEFT JOIN 
        movie_keyword mk ON h.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        h.movie_id, h.title, h.production_year, h.total_cast, h.lead_actors
)
SELECT 
    movie_id,
    title,
    production_year,
    total_cast,
    lead_actors,
    keywords
FROM 
    MovieDetails
WHERE 
    keywords IS NOT NULL
ORDER BY 
    production_year DESC, total_cast DESC;
