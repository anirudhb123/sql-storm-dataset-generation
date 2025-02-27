WITH MovieRankings AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT mk.keyword) AS total_keywords,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT mk.keyword) DESC) AS row_by_keywords
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id, title, production_year, 
        total_cast, total_keywords,
        CASE 
            WHEN rank_by_cast = 1 THEN 'Most Cast'
            ELSE 'Other'
        END AS cast_status
    FROM 
        MovieRankings
    WHERE 
        total_keywords > 0
    AND production_year IS NOT NULL
    UNION ALL
    SELECT 
        movie_id, title, production_year, 
        total_cast, total_keywords,
        'No Keywords' AS cast_status
    FROM 
        MovieRankings
    WHERE 
        total_keywords = 0
    AND production_year IS NOT NULL
),
CompaniesInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(c.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
FinalMovieReport AS (
    SELECT 
        f.movie_id,
        f.title,
        f.production_year,
        f.total_cast,
        f.total_keywords,
        f.cast_status,
        COALESCE(ci.companies, 'None') AS companies_info
    FROM 
        FilteredMovies f
    LEFT JOIN 
        CompaniesInfo ci ON f.movie_id = ci.movie_id
)
SELECT 
    *,
    CASE 
        WHEN total_cast > 10 THEN 'Large Cast'
        WHEN total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        WHEN total_cast = 0 THEN 'No Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    CONCAT(title, ' (', production_year, ')') AS movie_display
FROM 
    FinalMovieReport
WHERE 
    (cast_status = 'Most Cast' AND total_keywords > 3) OR 
    (cast_status = 'No Keywords' AND total_cast < 5)
ORDER BY 
    production_year DESC, total_cast DESC;
