
WITH RankedMovies AS (
    SELECT 
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT a.name) AS actors,
        RANK() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_within_year
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actors,
        rank_within_year
    FROM 
        RankedMovies
    WHERE 
        rank_within_year <= 5
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        k.keyword
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(NULLIF(tm.actors, ARRAY_CONSTRUCT()), ARRAY_CONSTRUCT('No actors found')) AS actors,
    LISTAGG(mk.keyword, ', ') WITHIN GROUP (ORDER BY mk.keyword) AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id IN (
        SELECT 
            m.id
        FROM 
            aka_title m
        WHERE 
            m.production_year = tm.production_year
    )
GROUP BY 
    tm.title, tm.production_year, tm.actors
ORDER BY 
    tm.production_year DESC, tm.title ASC;
