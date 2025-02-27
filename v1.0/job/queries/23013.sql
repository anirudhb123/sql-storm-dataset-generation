WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS ordered_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        *,
        CASE 
            WHEN cast_count > 5 THEN 'Ensemble' 
            WHEN cast_count = 1 THEN 'Solo' 
            ELSE 'Standard' 
        END AS cast_type
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 10
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
DetailedMovieInfo AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.cast_count,
        tm.ordered_cast,
        tm.cast_type,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = tm.movie_id) AS info_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
)
SELECT 
    dmi.title,
    dmi.production_year,
    dmi.cast_count,
    dmi.ordered_cast,
    dmi.cast_type,
    dmi.keywords,
    CASE 
        WHEN dmi.info_count >= 5 THEN 'Rich Info' 
        WHEN dmi.info_count = 0 THEN 'No Info Available' 
        ELSE 'Average Info' 
    END AS info_availability,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = dmi.movie_id AND cc.status_id IS NULL) AS unconfirmed_cast_count
FROM 
    DetailedMovieInfo dmi
WHERE 
    dmi.cast_type = 'Ensemble'
ORDER BY 
    dmi.production_year DESC, dmi.cast_count DESC
LIMIT 20;
