WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),

CelebrityTitles AS (
    SELECT 
        ak.name AS celebrity_name,
        ak.person_id,
        STRING_AGG(DISTINCT am.title, ', ') AS titles
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title am ON ci.movie_id = am.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.id, ak.person_id
)

SELECT 
    rt.title,
    rt.production_year,
    rt.cast_count,
    ct.celebrity_name,
    CASE 
        WHEN rt.cast_count > 5 THEN 'Large Cast'
        WHEN rt.cast_count BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    COALESCE(ct.titles, 'No titles found') AS movie_titles
FROM 
    RankedMovies rt
LEFT JOIN 
    CelebrityTitles ct ON rt.rank = 1
WHERE 
    rt.production_year BETWEEN 2000 AND 2023
ORDER BY 
    rt.production_year DESC,
    rt.cast_count DESC;
