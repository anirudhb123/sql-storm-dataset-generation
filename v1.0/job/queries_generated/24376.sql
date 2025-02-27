WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
),
FilteredRankedMovies AS (
    SELECT 
        *,
        CASE 
            WHEN cast_count >= 5 THEN 'Popular'
            WHEN cast_count IS NULL THEN 'Unknown'
            ELSE 'Less Known'
        END AS popularity
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 10
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
    FRM.year_rank,
    FRM.title,
    FRM.production_year,
    FRM.popularity,
    COALESCE(MK.keywords, 'No Keywords') AS keywords,
    COALESCE(info.info, 'No Info') AS additional_info
FROM 
    FilteredRankedMovies FRM
LEFT JOIN 
    movie_info info ON FRM.title = (SELECT title FROM aka_title WHERE movie_id = info.movie_id LIMIT 1)
LEFT JOIN 
    MovieKeywords MK ON FRM.title = (SELECT title FROM aka_title WHERE movie_id = MK.movie_id LIMIT 1)
WHERE 
    FRM.popularity IS NOT NULL
ORDER BY 
    FRM.production_year DESC, 
    FRM.year_rank;

-- Adding an outer join with obscure conditions
SELECT 
    FRM.title, 
    COALESCE(mn.name, 'Unknown Name') AS main_actor 
FROM 
    FilteredRankedMovies FRM
LEFT JOIN 
    cast_info ci ON FRM.title = (SELECT at.title FROM aka_title at WHERE at.movie_id = ci.movie_id)
LEFT JOIN 
    aka_name mn ON ci.person_id = mn.person_id 
WHERE 
    (ci.note IS NULL OR ci.note NOT LIKE '%Cameo%')
    AND FRM.cast_count > 3;
    
-- Incorporating Bizarre Semantics by checking for overlapping periods
SELECT
    DISTINCT FRM1.title,
    FRM1.production_year,
    FRM2.title AS related_movie
FROM 
    FilteredRankedMovies FRM1
JOIN 
    FilteredRankedMovies FRM2 ON FRM1.production_year = FRM2.production_year
WHERE 
    FRM1.title <> FRM2.title
    AND FRM1.year_rank > FRM2.year_rank;

