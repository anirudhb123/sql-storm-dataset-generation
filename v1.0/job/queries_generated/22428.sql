WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
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
MovieInfo AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Rating' THEN mi.info END) AS rating,
        MAX(CASE WHEN it.info = 'Duration' THEN mi.info END) AS duration
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    mv.movie_id,
    mv.title,
    mv.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mi.rating, 'Not Rated') AS movie_rating,
    COALESCE(mi.duration, 'Duration not available') AS movie_duration,
    COALESCE(cast_count, 0) AS cast_count
FROM 
    TopMovies mv
LEFT JOIN 
    MovieKeywords mk ON mv.movie_id = mk.movie_id
LEFT JOIN 
    MovieInfo mi ON mv.movie_id = mi.movie_id
LEFT JOIN 
    (SELECT movie_id, COUNT(DISTINCT person_id) AS cast_count
     FROM cast_info
     GROUP BY movie_id) AS cast ON mv.movie_id = cast.movie_id
ORDER BY 
    mv.production_year DESC, 
    cast_count DESC;

