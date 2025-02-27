
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS role_count,
        COUNT(DISTINCT cast_info.person_id) AS total_cast
    FROM 
        title
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.id, title.title, title.production_year
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mc.company_count, 0) AS company_count,
        COALESCE(ki.keyword_count, 0) AS keyword_count,
        CASE 
            WHEN rm.total_cast > 5 THEN 'High'
            WHEN rm.total_cast BETWEEN 3 AND 5 THEN 'Medium'
            ELSE 'Low'
        END AS cast_size_category
    FROM 
        RankedMovies rm
    LEFT JOIN (
        SELECT 
            movie_id, COUNT(*) AS company_count
        FROM 
            movie_companies
        GROUP BY 
            movie_id
    ) mc ON rm.movie_id = mc.movie_id
    LEFT JOIN (
        SELECT 
            movie_id, COUNT(DISTINCT keyword_id) AS keyword_count
        FROM 
            movie_keyword
        GROUP BY 
            movie_id
    ) ki ON rm.movie_id = ki.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_count,
    md.keyword_count,
    md.cast_size_category,
    SUBSTRING(md.title, 1, LENGTH(md.title) - 6) AS simplified_title,
    COALESCE((
        SELECT 
            STRING_AGG(name.name, ', ' ORDER BY cast_info.nr_order) 
        FROM 
            cast_info 
        JOIN 
            aka_name name ON cast_info.person_id = name.person_id 
        WHERE 
            cast_info.movie_id = md.movie_id
    ), 'No Cast') AS cast_names
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.cast_size_category ASC;
