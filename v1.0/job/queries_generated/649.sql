WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY mt.id) AS cast_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY mt.id) AS has_notes,
        ROW_NUMBER() OVER (ORDER BY mt.production_year DESC) AS rank
    FROM 
        aka_title mt
        LEFT JOIN complete_cast cc ON mt.id = cc.movie_id
        LEFT JOIN cast_info ci ON cc.subject_id = ci.id
),
FeaturedMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.has_notes,
        STRING_AGG(aka.name, ', ') AS cast_names
    FROM 
        RankedMovies rm
        LEFT JOIN aka_name aka ON aka.person_id IN (
            SELECT ci.person_id 
            FROM cast_info ci 
            WHERE ci.movie_id = rm.id
        )
    WHERE 
        rm.rank <= 10 AND 
        rm.production_year >= 2000
    GROUP BY 
        rm.title, rm.production_year, rm.cast_count, rm.has_notes
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.has_notes,
    CASE 
        WHEN fm.has_notes > 0 THEN 'Yes'
        ELSE 'No' 
    END AS notes_available,
    COALESCE(fm.cast_names, 'No Cast Found') AS cast_info
FROM 
    FeaturedMovies fm
ORDER BY 
    fm.production_year DESC;
