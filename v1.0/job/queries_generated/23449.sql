WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.id) AS rn,
        COUNT(*) OVER (PARTITION BY at.production_year) AS total_movies,
        COALESCE(NULLIF(CHAR_LENGTH(at.title), 0), NULL) AS title_length
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
)

, MovieKeywords AS (
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

, MovieInfoText AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_text
    FROM 
        movie_info mi
    WHERE 
        mi.info IS NOT NULL
    GROUP BY 
        mi.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    rm.rn,
    rm.total_movies,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mit.info_text, 'No info available') AS info_text,
    CASE 
        WHEN title_length > 50 THEN 'Long Title'
        WHEN title_length BETWEEN 30 AND 50 THEN 'Moderate Title'
        ELSE 'Short Title'
    END AS title_classification
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.id = mk.movie_id
LEFT JOIN 
    MovieInfoText mit ON rm.id = mit.movie_id
WHERE 
    rm.rn <= 3
    AND rm.production_year BETWEEN 2000 AND 2020
    AND (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = rm.id AND mc.company_type_id NOT IN (1, 5)) > 0
ORDER BY 
    rm.production_year, rm.title;
