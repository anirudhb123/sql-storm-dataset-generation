WITH MovieDetails AS (
    SELECT 
        a.title,
        a.production_year,
        COALESCE(SUM(mo.movie_id), 0) AS total_movie_companies,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER(PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM aka_title a
    LEFT JOIN movie_companies mo ON a.id = mo.movie_id
    LEFT JOIN complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.id
    WHERE 
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        AND a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
RankedMovies AS (
    SELECT 
        md.title,
        md.production_year,
        md.total_movie_companies,
        md.total_cast,
        md.year_rank,
        RANK() OVER(ORDER BY md.total_movie_companies DESC, md.total_cast DESC) AS company_rank
    FROM MovieDetails md
    WHERE md.total_cast > 0
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.total_movie_companies,
        rm.total_cast
    FROM RankedMovies rm
    WHERE rm.year_rank <= 5
)

SELECT 
    COALESCE(tm.title, 'No Title') AS Movie_Title,
    COALESCE(tm.production_year, 0) AS Production_Year,
    tm.total_movie_companies as Total_Companies,
    tm.total_cast AS Total_Cast,
    CASE 
        WHEN tm.total_cast IS NULL THEN 'No Cast Information'
        WHEN tm.total_cast = 0 THEN 'No Cast' 
        ELSE 'Has Cast Info' 
    END AS Cast_Information_Status
FROM TopMovies tm
UNION ALL 
SELECT 
    'Aggregate' AS Movie_Title,
    NULL AS Production_Year,
    SUM(total_movie_companies) AS Total_Companies,
    SUM(total_cast) AS Total_Cast
FROM RankedMovies
WHERE company_rank <= 5
GROUP BY 1
ORDER BY 
    Total_Companies DESC, Total_Cast DESC;
