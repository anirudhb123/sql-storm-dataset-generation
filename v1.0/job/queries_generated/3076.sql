WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS cast_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name cn ON ci.person_id = cn.person_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
), MovieInfo AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        COALESCE(mi.info, 'No additional info') AS additional_info
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_info mi ON md.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
)
SELECT 
    mi.movie_id,
    mi.title,
    mi.production_year,
    mi.additional_info,
    md.cast_count,
    md.cast_names
FROM 
    MovieInfo mi
LEFT JOIN 
    MovieDetails md ON mi.movie_id = md.movie_id
WHERE 
    md.cast_count > 3 OR mi.additional_info IS NOT NULL
ORDER BY 
    mi.production_year DESC, md.cast_count DESC;
