WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ARRAY_AGG(DISTINCT aka_name.name) AS actor_names,
        COUNT(DISTINCT movie_keyword.keyword_id) AS keyword_count,
        COUNT(DISTINCT movie_companies.company_id) AS company_count
    FROM 
        title
    INNER JOIN 
        cast_info ON cast_info.movie_id = title.id
    INNER JOIN 
        aka_name ON aka_name.person_id = cast_info.person_id
    LEFT JOIN 
        movie_keyword ON movie_keyword.movie_id = title.id
    LEFT JOIN 
        movie_companies ON movie_companies.movie_id = title.id
    GROUP BY 
        title.id, title.title, title.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_names,
        keyword_count,
        company_count
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000 AND
        keyword_count > 0
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.actor_names,
    fm.keyword_count,
    fm.company_count,
    COALESCE((SELECT COUNT(*) FROM movie_info WHERE movie_id = fm.movie_id), 0) AS info_count
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, 
    fm.keyword_count DESC, 
    fm.company_count ASC
LIMIT 100;
