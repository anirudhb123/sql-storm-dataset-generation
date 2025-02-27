WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        AVG(CASE WHEN mi.info IS NOT NULL AND mi.info <> '' THEN 1 ELSE 0 END) AS has_info
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_info mi ON at.movie_id = mi.movie_id
    WHERE 
        at.production_year IS NOT NULL 
    GROUP BY 
        at.title, at.production_year
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        CASE 
            WHEN title_rank > 10 THEN 'Top Finalist'
            WHEN total_cast > 5 THEN 'Ensemble Cast'
            ELSE 'Independent'
        END AS movie_category,
        actors,
        has_info
    FROM 
        RankedMovies
    WHERE
        has_info > 0.5
)
SELECT 
    fm.production_year,
    fm.movie_category,
    COUNT(*) AS movies_count,
    STRING_AGG(fm.title, '; ') AS movies_list
FROM 
    FilteredMovies fm
LEFT JOIN 
    (SELECT DISTINCT year.production_year
     FROM 
         (SELECT DISTINCT production_year FROM aka_title WHERE production_year IS NOT NULL) AS year) AS AllYears
ON 
    fm.production_year = AllYears.production_year
GROUP BY 
    fm.production_year, fm.movie_category
HAVING 
    COUNT(*) >= 2 
ORDER BY 
    fm.production_year DESC, movies_count DESC;