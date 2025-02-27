
WITH RankedMovies AS (
    SELECT 
        a.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY a.title) AS rank,
        t.id  -- Assuming there is an id column in title table for correctly joining later
    FROM 
        aka_title a
    JOIN 
        title t ON a.title = t.title
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
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
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    m.title,
    m.production_year,
    cd.cast_count,
    cd.cast_names,
    k.keywords
FROM 
    RankedMovies m
JOIN 
    CastDetails cd ON m.id = cd.movie_id
JOIN 
    MovieKeywords k ON m.id = k.movie_id
WHERE 
    m.rank <= 10
ORDER BY 
    m.production_year DESC, 
    m.title;
