WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(ci.person_id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
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
MovieInfoSummary AS (
    SELECT 
        m.movie_id,
        COALESCE(STRING_AGG(DISTINCT mi.info, '; '), 'No Info') AS info_summary
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.title_rank,
    rm.cast_count,
    COALESCE(mks.keywords, 'No Keywords') AS keywords,
    COALESCE(mis.info_summary, 'No Summary') AS info_summary,
    CASE 
        WHEN rm.production_year < 2000 THEN 'Classic'
        WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mks ON rm.movie_id = mks.movie_id
LEFT JOIN 
    MovieInfoSummary mis ON rm.movie_id = mis.movie_id
WHERE 
    rm.cast_count > 0
ORDER BY 
    rm.production_year DESC, rm.title_rank ASC;
