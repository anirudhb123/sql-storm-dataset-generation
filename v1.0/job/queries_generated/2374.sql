WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
        JOIN cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
HighlyRatedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompleteMovieInfo AS (
    SELECT 
        hm.title,
        hm.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(ci.note, 'No Cast Info') AS cast_info
    FROM 
        HighlyRatedMovies hm
        LEFT JOIN MovieKeywords mk ON hm.movie_id = mk.movie_id
        LEFT JOIN complete_cast ci ON hm.movie_id = ci.movie_id
)
SELECT 
    cm.title,
    cm.production_year,
    cm.keywords,
    CASE 
        WHEN cm.cast_info IS NULL THEN 'Unknown Cast'
        ELSE cm.cast_info
    END AS cast_info_display
FROM 
    CompleteMovieInfo cm
WHERE 
    cm.production_year > 2000
ORDER BY 
    cm.production_year DESC,
    cm.title;
