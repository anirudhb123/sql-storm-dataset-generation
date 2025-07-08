
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
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
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
