WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
RecentMovies AS (
    SELECT 
        title,
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        production_year IS NOT NULL AND rank <= 10
),
MaxCast AS (
    SELECT 
        MAX(total_cast) AS max_cast FROM RecentMovies
), 
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.total_cast,
        CASE 
            WHEN rm.total_cast = mc.max_cast THEN 'Most Star-Studded' 
            ELSE 'Regular Cast' 
        END AS cast_label
    FROM 
        RecentMovies rm
    CROSS JOIN 
        MaxCast mc
)
SELECT 
    fm.title AS movie_title,
    fm.production_year,
    fm.total_cast,
    fm.cast_label,
    coalesce(NULLIF(at.kind_id, 0), 'Unknown') AS movie_kind
FROM 
    FilteredMovies fm
LEFT JOIN 
    aka_title at ON fm.title = at.title AND fm.production_year = at.production_year
WHERE 
    fm.cast_label = 'Most Star-Studded' 
    OR (fm.total_cast < 5 AND at.production_year > 2000)
ORDER BY 
    fm.production_year DESC, 
    fm.total_cast DESC;
