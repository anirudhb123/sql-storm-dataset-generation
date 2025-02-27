
WITH MovieTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS main_cast,
        CASE 
            WHEN t.production_year < 2000 THEN 'Pre-2000' 
            ELSE 'Post-2000' 
        END AS era
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        MAX(mi.info) AS longest_info
    FROM 
        movie_info m
    LEFT JOIN 
        movie_info_idx mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
),
FinalResults AS (
    SELECT 
        mt.title_id,
        mt.title,
        mt.production_year,
        mt.cast_count,
        mt.main_cast,
        mt.era,
        mi.longest_info
    FROM 
        MovieTitles mt
    LEFT JOIN 
        MovieInfo mi ON mt.title_id = mi.movie_id
    WHERE 
        mt.production_year IS NOT NULL
)
SELECT 
    title_id,
    title,
    production_year,
    cast_count,
    COALESCE(main_cast, 'No Cast') AS main_cast,
    era,
    COALESCE(longest_info, 'No Information Available') AS longest_info
FROM 
    FinalResults
WHERE 
    cast_count > 0
ORDER BY 
    production_year DESC, cast_count DESC
LIMIT 10;
