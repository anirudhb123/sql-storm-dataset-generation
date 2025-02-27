WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(c.id) AS cast_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info c ON at.id = c.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
HighCastMovies AS (
    SELECT 
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS infos,
        STRING_AGG(DISTINCT it.info, '; ') AS notes
    FROM 
        movie_info mi
    INNER JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    hcm.title,
    hcm.production_year,
    COALESCE(mi.infos, 'No Info') AS additional_info,
    COALESCE(mi.notes, 'No Notes') AS additional_notes,
    CASE 
        WHEN hcm.production_year < 2000 THEN 'Classic'
        WHEN hcm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_category
FROM 
    HighCastMovies hcm
LEFT JOIN 
    MovieInfo mi ON hcm.title = (SELECT title FROM aka_title WHERE production_year = hcm.production_year LIMIT 1)
ORDER BY 
    hcm.production_year DESC, hcm.title;
