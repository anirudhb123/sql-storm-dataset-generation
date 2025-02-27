WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        cast_count > 5
),
KeywordRanked AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_keyword mk ON fm.movie_id = mk.movie_id
    GROUP BY 
        fm.movie_id, fm.title, fm.production_year
)
SELECT 
    km.movie_id,
    km.title,
    km.production_year,
    COALESCE(kr.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN km.production_year = EXTRACT(YEAR FROM CURRENT_DATE) THEN 'Released this Year'
        ELSE 'Released Earlier'
    END AS release_status
FROM 
    FilteredMovies km
LEFT JOIN 
    KeywordRanked kr ON km.movie_id = kr.movie_id
WHERE 
    km.production_year BETWEEN 1990 AND 2023
ORDER BY 
    km.production_year DESC, 
    keyword_count DESC
FETCH FIRST 10 ROWS ONLY;
