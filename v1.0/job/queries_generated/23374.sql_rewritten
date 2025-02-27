WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        t.id AS title_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
    AND 
        t.title IS NOT NULL
), 
MovieWithCast AS (
    SELECT 
        c.movie_id,
        COUNT(*) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
), 
CastMovies AS (
    SELECT 
        m.movie_id,
        m.cast_count,
        m.cast_names,
        t.title,
        t.production_year,
        COALESCE(mv.info, 'No additional info') AS additional_info
    FROM 
        MovieWithCast m
    LEFT JOIN 
        RankedTitles t ON m.movie_id = t.title_id
    LEFT JOIN 
        movie_info mv ON m.movie_id = mv.movie_id AND mv.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot' LIMIT 1)
    WHERE 
        t.rn = 1 OR t.rn IS NULL 
), 
FinalList AS (
    SELECT 
        cm.title,
        cm.production_year,
        cm.cast_count,
        cm.cast_names,
        CASE 
            WHEN cm.cast_count > 5 THEN 'Blockbuster'
            WHEN cm.cast_count BETWEEN 3 AND 5 THEN 'Moderate Cast'
            ELSE 'Low Cast'
        END AS cast_category
    FROM 
        CastMovies cm 
    WHERE 
        cm.production_year >= 2000
    ORDER BY 
        cm.production_year DESC,
        cm.cast_count DESC
)
SELECT 
    fl.title,
    fl.production_year,
    fl.cast_count,
    fl.cast_names,
    fl.cast_category,
    CASE 
        WHEN fl.cast_count IS NULL THEN 'No Cast Information Available'
        ELSE 'Cast Information Present'
    END AS cast_info_status
FROM 
    FinalList fl
WHERE 
    fl.cast_category = 'Blockbuster' 
    OR fl.cast_category = 'Moderate Cast'
UNION ALL 
SELECT 
    NULL AS title,
    NULL AS production_year,
    NULL AS cast_count,
    NULL AS cast_names,
    NULL AS cast_category,
    'No Blockbuster or Moderate Cast Movies Found' AS cast_info_status
WHERE NOT EXISTS (
    SELECT 1 
    FROM FinalList 
    WHERE cast_category IN ('Blockbuster', 'Moderate Cast')
);