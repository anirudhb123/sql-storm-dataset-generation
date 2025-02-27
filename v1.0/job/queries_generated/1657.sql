WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND t.production_year IS NOT NULL
),
CastCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MoviesWithDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        cc.total_cast,
        COALESCE(mk.keyword, 'No Keywords') AS keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastCounts cc ON rm.title = (SELECT at.title FROM aka_title at WHERE at.id = cc.movie_id)
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT at.id FROM aka_title at WHERE at.title = rm.title LIMIT 1)
    WHERE 
        rm.year_rank <= 5
)
SELECT 
    mw.title,
    mw.production_year,
    mw.total_cast,
    mw.keyword,
    CASE 
        WHEN mw.total_cast IS NULL THEN 'No Cast Information'
        WHEN mw.total_cast > 10 THEN 'Large Cast'
        ELSE 'Small Cast'
    END AS cast_size_description
FROM 
    MoviesWithDetails mw
ORDER BY 
    mw.production_year DESC, mw.title;
