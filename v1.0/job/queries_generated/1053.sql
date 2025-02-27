WITH movie_years AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count
    FROM 
        title
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.id, title.title, title.production_year
),
movie_keywords AS (
    SELECT 
        movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_id
),
company_movies AS (
    SELECT 
        movie_companies.movie_id,
        STRING_AGG(company_name.name, ', ') AS companies
    FROM 
        movie_companies
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    GROUP BY 
        movie_companies.movie_id
)
SELECT 
    my.movie_id,
    my.title,
    my.production_year,
    COALESCE(my.cast_count, 0) AS cast_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(cm.companies, 'No companies') AS companies
FROM 
    movie_years my
LEFT JOIN 
    movie_keywords mk ON my.movie_id = mk.movie_id
LEFT JOIN 
    company_movies cm ON my.movie_id = cm.movie_id
WHERE 
    my.production_year BETWEEN 2000 AND 2023
    AND my.cast_count > (
        SELECT AVG(cast_count)
        FROM movie_years
    )
ORDER BY 
    my.production_year DESC, 
    my.cast_count DESC;
