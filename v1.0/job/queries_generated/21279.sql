WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_with_most_cast,
        STRING_AGG(DISTINCT ka.name, ', ') AS cast_names,
        COALESCE(SUM(CASE WHEN cc.kind LIKE 'Animation%' THEN 1 ELSE 0 END), 0) AS animation_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = 1
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_names,
        CASE 
            WHEN rm.rank_with_most_cast = 1 THEN 'Top Cast'
            ELSE 'Other'
        END AS cast_category,
        rm.animation_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.animation_count > 2
),
FinalMovieStats AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.cast_names,
        fm.cast_category,
        (SELECT COUNT(*) FROM movie_info WHERE movie_id = fm.movie_id) AS info_count
    FROM 
        FilteredMovies fm
)
SELECT 
    fms.movie_id, 
    fms.title, 
    fms.production_year,
    fms.cast_names,
    fms.cast_category,
    fms.info_count,
    CASE 
        WHEN fms.info_count > 5 THEN 'Rich Info'
        WHEN fms.info_count BETWEEN 2 AND 5 THEN 'Moderate Info'
        ELSE 'Minimal Info'
    END AS info_quality,
    COALESCE(NULLIF(fms.cast_names, ''), 'No Cast Available') AS cast_display
FROM 
    FinalMovieStats fms
ORDER BY 
    fms.production_year DESC, fms.cast_category;
