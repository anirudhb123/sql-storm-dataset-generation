WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        c.name AS company_name,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.id
    GROUP BY 
        at.title, at.production_year, c.name
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        company_name,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        GROUP_CONCAT(mk.keyword) AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword mk ON mt.keyword_id = mk.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_name,
    tm.cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN tm.cast_count IS NULL THEN 'Unknown Cast'
        ELSE CAST(tm.cast_count AS TEXT)
    END AS cast_count_text
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
