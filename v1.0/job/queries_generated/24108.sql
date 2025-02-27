WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
        LEFT JOIN cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title,
        at.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        RANK() OVER (ORDER BY rm.cast_count DESC) AS cast_rank
    FROM
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        COALESCE(mi.info, 'No additional info available.') AS movie_info,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
    FROM 
        TopMovies tm
        LEFT JOIN movie_info mi ON tm.title = mi.info AND mi.note IS NULL
        LEFT JOIN movie_keyword mk ON mk.movie_id = (
            SELECT id FROM aka_title WHERE title = tm.title LIMIT 1
        )
        LEFT JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY 
        tm.title, 
        tm.production_year, 
        tm.cast_count
),
FinalOutput AS (
    SELECT 
        md.title AS Movie_Title,
        md.production_year AS Production_Year,
        md.cast_count AS Cast_Count,
        md.movie_info AS Additional_Info,
        CASE 
            WHEN md.keywords IS NOT NULL THEN 'Keywords: ' || md.keywords 
            ELSE 'No Keywords Found'
        END AS Keyword_Info
    FROM 
        MovieDetails md
    WHERE 
        md.cast_count > 2
)
SELECT 
    FO.Movie_Title,
    FO.Production_Year,
    FO.Cast_Count,
    FO.Additional_Info,
    FO.Keyword_Info
FROM 
    FinalOutput FO
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM movie_companies mc
        WHERE mc.movie_id = (
            SELECT id FROM aka_title WHERE title = FO.Movie_Title LIMIT 1
        ) 
        AND mc.note IS NULL
    )
ORDER BY 
    FO.Production_Year DESC, 
    FO.Cast_Count DESC;
