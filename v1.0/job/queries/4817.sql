WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
), CastDetails AS (
    SELECT 
        c.movie_id,
        COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'No Cast') AS cast_names,
        COUNT(c.person_id) AS total_cast,
        MAX(r.role) AS highest_role
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        role_type r ON r.id = c.role_id
    GROUP BY 
        c.movie_id
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    cd.cast_names,
    cd.total_cast,
    cd.highest_role,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN rm.production_year < 2000 THEN 'Classic'
        WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON cd.movie_id = rm.movie_id
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = rm.movie_id
WHERE 
    cd.total_cast > 0
ORDER BY 
    rm.production_year DESC, rm.movie_title;
