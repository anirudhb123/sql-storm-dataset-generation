WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(co.movie_id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.id = ci.movie_id
    LEFT JOIN 
        aka_name n ON ci.person_id = n.person_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.production_year > 1950
        AND n.name IS NOT NULL
),

FilteredMovies AS (
    SELECT 
        rm.*,
        CASE 
            WHEN rm.cast_count > 5 THEN 'Highly Casted'
            WHEN rm.cast_count BETWEEN 3 AND 5 THEN 'Moderately Casted'
            ELSE 'Low Casted'
        END AS cast_category
    FROM 
        RankedMovies rm
),

DistinctKeywords AS (
    SELECT 
        DISTINCT mk.movie_id, 
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        LENGTH(k.keyword) > 5
),

MovieKeywordCounts AS (
    SELECT 
        fk.movie_id, 
        COUNT(dk.keyword) AS keyword_count
    FROM 
        FilteredMovies fk
    LEFT JOIN 
        DistinctKeywords dk ON fk.movie_id = dk.movie_id
    GROUP BY 
        fk.movie_id
)

SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.title_rank,
    fm.cast_count,
    fm.cast_category,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieKeywordCounts mkc ON fm.movie_id = mkc.movie_id
LEFT JOIN 
    movie_keyword mk ON fm.movie_id = mk.movie_id
WHERE 
    (fm.cast_category = 'Highly Casted' AND mkc.keyword_count > 3) 
    OR (fm.cast_category = 'Moderately Casted' AND mkc.keyword_count IS NULL)
    OR (fm.production_year BETWEEN 2000 AND 2020 AND mk.keyword IS NOT NULL)
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, 
    fm.title_rank, fm.cast_count, fm.cast_category, mkc.keyword_count
HAVING 
    COUNT(DISTINCT mk.keyword) < 10
ORDER BY 
    fm.production_year DESC, 
    fm.title_rank ASC;
