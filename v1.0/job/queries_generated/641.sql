WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(ci.id) OVER (PARTITION BY at.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        *,
        COALESCE((SELECT GROUP_CONCAT(name) FROM aka_name an WHERE an.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = rm.movie_id)), 'Unknown Cast') AS cast_names
    FROM 
        RankedMovies rm
    WHERE 
        rank <= 10
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.cast_count,
        tm.cast_names,
        it.info AS imdb_rating
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info LIKE '%rating%'
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.cast_names,
    COALESCE(md.imdb_rating, 'No Rating Available') AS imdb_rating
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
