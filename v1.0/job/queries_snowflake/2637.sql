
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS year_rank
    FROM title
    WHERE title.production_year IS NOT NULL
), MovieKeywords AS (
    SELECT 
        movie_id,
        LISTAGG(keyword.keyword, ', ') WITHIN GROUP (ORDER BY keyword.keyword) AS keywords
    FROM movie_keyword
    JOIN keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY movie_id
), MovieInfo AS (
    SELECT 
        movie_id,
        LISTAGG(movie_info.info, '; ') WITHIN GROUP (ORDER BY movie_info.info) AS info_details
    FROM movie_info
    GROUP BY movie_id
), CastDetails AS (
    SELECT
        cast_info.movie_id,
        COUNT(cast_info.id) AS cast_count,
        LISTAGG(DISTINCT aka_name.name, ', ') WITHIN GROUP (ORDER BY aka_name.name) AS cast_names
    FROM cast_info
    JOIN aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY cast_info.movie_id
)

SELECT 
    rm.movie_id,
    rm.movie_title,
    COALESCE(CAST(rm.production_year AS VARCHAR), 'Unknown') AS production_year,
    C.cast_count,
    C.cast_names,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mi.info_details, 'No additional info') AS additional_info
FROM RankedMovies rm
LEFT JOIN CastDetails C ON rm.movie_id = C.movie_id
LEFT JOIN MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    (C.cast_count > 5 OR C.cast_count IS NULL)
    AND rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title ASC;
