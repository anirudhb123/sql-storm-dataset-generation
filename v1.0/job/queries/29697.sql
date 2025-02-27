WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ca ON cc.subject_id = ca.id
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), 
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
), 
MovieInfo AS (
    SELECT
        mi.movie_id,
        STRING_AGG(DISTINCT it.info, ', ') AS info_types
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.cast_names,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mi.info_types, 'No additional info') AS additional_info
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast DESC;
