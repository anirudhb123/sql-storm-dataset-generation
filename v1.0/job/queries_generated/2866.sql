WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
HighCastMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
SelectedMovies AS (
    SELECT 
        hm.title,
        hm.production_year,
        COALESCE(mi.info, 'No additional info available') AS additional_info,
        kc.keyword
    FROM 
        HighCastMovies hm
    LEFT JOIN 
        movie_info mi ON hm.production_year = mi.movie_id AND mi.info_type_id = 1
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = hm.production_year
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
),
FinalResults AS (
    SELECT 
        sm.title,
        sm.production_year,
        STRING_AGG(sm.keyword, ', ') AS keywords
    FROM 
        SelectedMovies sm
    GROUP BY 
        sm.title, sm.production_year
)
SELECT 
    fr.title,
    fr.production_year,
    fr.keywords
FROM 
    FinalResults fr
WHERE 
    fr.keywords IS NOT NULL
ORDER BY 
    fr.production_year DESC, fr.title;
