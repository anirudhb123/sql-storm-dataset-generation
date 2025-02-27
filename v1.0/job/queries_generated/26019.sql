WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS director_name,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
HighCastMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title,
        rm.production_year,
        rm.director_name,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10 -- Top 10 movies with the most cast members per year
)
SELECT 
    hcm.title AS Movie_Title,
    hcm.production_year AS Release_Year,
    hcm.director_name AS Director,
    hcm.cast_count AS Total_Cast,
    COALESCE(GROUP_CONCAT(DISTINCT a.name ORDER BY a.name SEPARATOR ', '), 'No Cast Available') AS Cast_Names
FROM 
    HighCastMovies hcm
LEFT JOIN 
    complete_cast cc ON hcm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
GROUP BY 
    hcm.movie_id, hcm.title, hcm.production_year, hcm.director_name, hcm.cast_count
ORDER BY 
    hcm.production_year DESC, hcm.cast_count DESC;

This SQL query accomplishes a multi-step analysis focusing on movies with high cast counts, ranking them by year. It uses Common Table Expressions (CTEs) for clarity and organizes results for easier interpretation. The final output includes the title, release year, director, total cast members, and a list of cast names for the top 10 movies per production year, facilitating a benchmark on string processing around the cast names extraction.
