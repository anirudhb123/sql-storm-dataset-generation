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
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        MAX(CASE WHEN co.kind = 'Director' THEN 1 ELSE 0 END) AS has_director
    FROM 
        cast_info c
    LEFT JOIN 
        comp_cast_type co ON c.person_role_id = co.id
    GROUP BY 
        c.movie_id
)
SELECT 
    m.title,
    m.production_year,
    mk.keywords,
    cd.total_cast,
    COALESCE(cd.has_director, 0) AS has_director
FROM 
    RankedMovies m
LEFT JOIN 
    MovieKeywords mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    CastDetails cd ON m.movie_id = cd.movie_id
WHERE 
    m.rank_per_year <= 5
ORDER BY 
    m.production_year DESC, 
    m.title;
