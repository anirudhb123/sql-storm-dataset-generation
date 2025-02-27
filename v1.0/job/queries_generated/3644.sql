WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
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
FilteredMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        CASE 
            WHEN rm.cast_count > 5 THEN 'High'
            WHEN rm.cast_count BETWEEN 3 AND 5 THEN 'Medium'
            ELSE 'Low'
        END AS cast_category
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= 2000
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title at ON mk.movie_id = at.movie_id
    WHERE 
        at.production_year >= 2000
)
SELECT 
    fm.movie_title,
    fm.production_year,
    fm.cast_count,
    fm.cast_category,
    STRING_AGG(mk.keyword, ', ') AS keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id IN (SELECT movie_id FROM aka_title WHERE title = fm.movie_title)
WHERE 
    (fm.cast_category = 'High' OR fm.cast_count IS NULL)
GROUP BY 
    fm.movie_title, fm.production_year, fm.cast_count, fm.cast_category
ORDER BY 
    fm.production_year DESC, fm.cast_count DESC;
