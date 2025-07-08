
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighCastMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS info_details
    FROM 
        movie_info mi
    JOIN 
        HighCastMovies hcm ON mi.movie_id = hcm.movie_id
    GROUP BY 
        mi.movie_id
)
SELECT 
    hcm.title,
    hcm.production_year,
    COALESCE(mi.info_details, 'No Info Available') AS additional_info,
    CASE 
        WHEN hc.cast_count IS NOT NULL THEN hc.cast_count 
        ELSE 0 
    END AS total_cast,
    NULLIF(hcm.production_year, 0) AS production_year_flag
FROM 
    HighCastMovies hcm
LEFT JOIN 
    (SELECT 
        t.id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
     FROM 
        aka_title t
     JOIN 
        complete_cast cc ON t.id = cc.movie_id
     JOIN 
        cast_info ci ON cc.subject_id = ci.id
     GROUP BY 
        t.id) hc ON hcm.movie_id = hc.movie_id
LEFT JOIN 
    MovieInfo mi ON hcm.movie_id = mi.movie_id
ORDER BY 
    hcm.production_year DESC, hcm.title ASC;
