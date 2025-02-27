WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        COUNT(ci.id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
MovieKeyword AS (
    SELECT 
        at.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    COALESCE(rm.total_cast, 0) AS total_cast,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN rm.rank <= 5 THEN 'Top 5 Movies'
        ELSE 'Other Movies'
    END AS category
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeyword mk ON rm.movie_title = mk.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC;
