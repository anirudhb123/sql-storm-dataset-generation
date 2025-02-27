WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank,
        COUNT(c.id) OVER (PARTITION BY m.id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        m.production_year IS NOT NULL
),
PopularMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5 AND cast_count > 2
),
KeywordedMovies AS (
    SELECT 
        pm.movie_id,
        pm.title,
        pm.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        PopularMovies pm
    LEFT JOIN 
        movie_keyword mk ON pm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        pm.movie_id, pm.title, pm.production_year
),
FinalResults AS (
    SELECT 
        km.movie_id,
        km.title,
        km.production_year,
        km.keywords,
        COALESCE(ci.note, 'No role info') AS role_info
    FROM 
        KeywordedMovies km
    LEFT JOIN 
        cast_info ci ON km.movie_id = ci.movie_id
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.keywords,
    COUNT(fr.role_info) AS total_roles,
    CASE 
        WHEN COUNT(fr.role_info) > 5 THEN 'Diverse Cast'
        ELSE 'Limited Roles'
    END AS cast_diversity
FROM 
    FinalResults fr
GROUP BY 
    fr.movie_id, fr.title, fr.production_year, fr.keywords
ORDER BY 
    fr.production_year DESC, total_roles DESC;
