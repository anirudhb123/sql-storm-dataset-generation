
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rank_per_year
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
MaxYear AS (
    SELECT 
        MAX(production_year) AS max_year
    FROM 
        aka_title
),
CoActors AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS co_actor_count
    FROM 
        cast_info c
    JOIN 
        RankedMovies r ON c.movie_id = r.movie_id
    GROUP BY 
        c.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    r.title,
    r.production_year,
    COALESCE(c.co_actor_count, 0) AS co_actor_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    RankedMovies r
LEFT JOIN 
    CoActors c ON r.movie_id = c.movie_id
LEFT JOIN 
    MovieKeywords mk ON r.movie_id = mk.movie_id
WHERE 
    r.production_year = (SELECT max_year FROM MaxYear)
    AND r.rank_per_year <= 5
ORDER BY 
    r.production_year DESC, 
    r.title;
