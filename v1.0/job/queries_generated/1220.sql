WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank,
        COUNT(ci.person_id) AS cast_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
), 
DirectorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS director_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        rt.role = 'director'
    GROUP BY 
        ci.movie_id
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
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(dc.director_count, 0) AS director_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    DirectorCounts dc ON rm.title = (SELECT title FROM aka_title WHERE movie_id = dc.movie_id)
LEFT JOIN 
    MovieKeywords mk ON rm.title = (SELECT at.title FROM aka_title at WHERE at.movie_id = mk.movie_id)
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
