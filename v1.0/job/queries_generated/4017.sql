WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_title
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
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
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(r.role) AS lead_role
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
MoviesWithDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(cd.total_cast, 0) AS total_cast,
        COALESCE(cd.lead_role, 'N/A') AS lead_role
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
)

SELECT 
    m.title,
    m.production_year,
    m.keywords,
    m.total_cast,
    m.lead_role
FROM 
    MoviesWithDetails m
WHERE 
    m.production_year BETWEEN 2000 AND 2020
    AND m.total_cast > 5
ORDER BY 
    m.production_year DESC, m.title;


