WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year, 
        at.kind_id,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank,
        COUNT(*) OVER (PARTITION BY at.kind_id) AS kind_count
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
        AND at.title IS NOT NULL
), 
TopMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        cm.name AS company_name, 
        COUNT(DISTINCT ci.person_id) AS num_cast 
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.id = mc.movie_id
    LEFT JOIN 
        company_name cm ON mc.company_id = cm.id
    LEFT JOIN 
        cast_info ci ON rm.id = ci.movie_id
    WHERE 
        rm.year_rank <= 5
    GROUP BY 
        rm.title, rm.production_year, cm.name
), 
MoviesWithKeywords AS (
    SELECT 
        tm.title, 
        tm.production_year, 
        k.keyword,
        COALESCE(tm.num_cast, 0) AS num_cast
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
), 
UniqueKeywords AS (
    SELECT 
        title, 
        STRING_AGG(DISTINCT keyword, ', ') AS keywords
    FROM 
        MoviesWithKeywords
    GROUP BY 
        title
)
SELECT 
    uk.title, 
    uk.keywords, 
    COALESCE(uk.num_cast, 0) AS num_cast
FROM 
    UniqueKeywords uk
WHERE 
    EXISTS (
        SELECT 1 
        FROM MoviesWithKeywords mw 
        WHERE mw.title = uk.title 
        AND mw.keyword IS NULL
    )
ORDER BY 
    num_cast DESC, title
LIMIT 10;
