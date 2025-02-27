WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank,
        COALESCE(CAST(COUNT(DISTINCT c.person_id) AS INTEGER), 0) AS cast_count,
        COALESCE(SUM(CASE WHEN i.info_type_id = 1 THEN 1 ELSE 0 END), 0) AS has_award
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    LEFT JOIN 
        movie_info i ON i.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        rank,
        cast_count,
        has_award
    FROM 
        RankedMovies
    WHERE 
        rank <= 5 AND cast_count > 0
)
SELECT 
    f.movie_id,
    f.title,
    f.cast_count,
    CASE 
        WHEN f.has_award > 0 THEN 'Award Winner' 
        ELSE 'No Awards' 
    END AS award_status
FROM 
    FilteredMovies f
ORDER BY 
    f.cast_count DESC, f.title ASC
LIMIT 10
UNION
SELECT 
    NULL AS movie_id,
    'Total Cast Count:' AS title,
    COUNT(*) AS cast_count,
    NULL AS award_status
FROM 
    cast_info
WHERE 
    person_id IS NOT NULL;
