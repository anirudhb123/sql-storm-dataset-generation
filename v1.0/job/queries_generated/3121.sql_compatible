
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank
    FROM 
        title
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.id, title.title, title.production_year
),
MovieDetails AS (
    SELECT 
        R.movie_id,
        R.title,
        R.production_year,
        COALESCE(mci.note, 'No note') AS company_note,
        COALESCE(GROUP_CONCAT(DISTINCT keyword.keyword), 'No keywords') AS keywords
    FROM 
        RankedMovies R
    LEFT JOIN 
        movie_companies mci ON R.movie_id = mci.movie_id
    LEFT JOIN 
        movie_keyword mk ON R.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ON mk.keyword_id = keyword.id
    WHERE 
        R.rank <= 5
    GROUP BY 
        R.movie_id, R.title, R.production_year, mci.note
)
SELECT 
    MD.title,
    MD.production_year,
    RM.cast_count,
    MD.company_note,
    MD.keywords,
    NULLIF(MD.keywords, 'No keywords') AS adjusted_keywords,
    CASE 
        WHEN MD.production_year < 2000 THEN 'Classic'
        ELSE 'Modern'
    END AS movie_category
FROM 
    RankedMovies RM
JOIN 
    MovieDetails MD ON RM.movie_id = MD.movie_id
ORDER BY 
    MD.production_year DESC, RM.cast_count DESC;
