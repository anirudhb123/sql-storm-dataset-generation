WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.movie_id, at.title, at.production_year
), TitleKeywords AS (
    SELECT 
        at.id AS title_id, 
        k.keyword
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
), PopularKeywords AS (
    SELECT 
        keyword, 
        COUNT(DISTINCT title_id) AS keyword_count
    FROM 
        TitleKeywords
    GROUP BY 
        keyword
    HAVING 
        COUNT(DISTINCT title_id) > 5
)
SELECT 
    rm.title, 
    rm.production_year, 
    rm.cast_count,
    COALESCE(pkw.keyword, 'No Popular Keyword') AS popular_keyword
FROM 
    RankedMovies rm
LEFT JOIN 
    PopularKeywords pkw ON rm.title = (
        SELECT 
            tk.title 
        FROM 
            TitleKeywords tk 
        WHERE 
            tk.keyword = pkw.keyword 
        LIMIT 1
    )
WHERE 
    rm.year_rank <= 3
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
