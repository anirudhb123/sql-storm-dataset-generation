
WITH MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),

MovieInfoText AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ') AS info_text
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),

CompleteMovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        COALESCE(mit.info_text, '') AS info_text
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id AND cc.movie_id = ci.movie_id
    LEFT JOIN 
        MovieKeywordCounts mkc ON t.id = mkc.movie_id
    LEFT JOIN 
        MovieInfoText mit ON t.id = mit.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.title, t.production_year, mkc.keyword_count, mit.info_text
    ORDER BY 
        t.production_year DESC, cast_count DESC
)

SELECT 
    cd.title,
    cd.production_year,
    cd.cast_count,
    cd.keyword_count,
    cd.info_text
FROM 
    CompleteMovieDetails cd
WHERE 
    cd.cast_count > 0
LIMIT 50;
