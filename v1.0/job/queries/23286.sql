WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT CONCAT_WS(' ', ak.name), ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        c.movie_id
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),

MoviesWithDetails AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        cd.total_cast,
        cd.cast_names,
        mk.keywords,
        COALESCE(mi.info, 'No Info') AS movie_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.title_id = cd.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.title_id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON rm.title_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot' LIMIT 1)
)

SELECT 
    m.title,
    m.production_year,
    m.total_cast,
    m.cast_names,
    COALESCE(m.keywords, 'Uncategorized') AS keywords,
    CASE 
        WHEN m.total_cast IS NULL OR m.total_cast = 0 THEN 'This movie has no cast.'
        WHEN m.production_year < 2000 THEN 'Classic film from the 20th century.'
        ELSE 'A modern movie experience.'
    END AS movie_description
FROM 
    MoviesWithDetails m
WHERE 
    m.production_year BETWEEN 1980 AND 2023
ORDER BY 
    m.production_year DESC, 
    m.title;