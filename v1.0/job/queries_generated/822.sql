WITH movie_role_stats AS (
    SELECT 
        t.title AS movie_title,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(COALESCE(CASE WHEN r.role = 'Director' THEN 1 ELSE 0 END, 0)) AS avg_directors,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        t.title
),
movie_info_with_keywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_info m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
),
comprehensive_movie_data AS (
    SELECT 
        mrs.movie_title,
        mrs.total_cast,
        mrs.avg_directors,
        mrs.first_year,
        mrs.last_year,
        COALESCE(mikw.keywords, 'No keywords') AS keywords
    FROM 
        movie_role_stats mrs
    LEFT JOIN 
        movie_info_with_keywords mikw ON mrs.movie_title = mikw.movie_id
)
SELECT 
    cmd.movie_title,
    cmd.total_cast,
    cmd.avg_directors,
    cmd.first_year,
    cmd.last_year,
    cmd.keywords
FROM 
    comprehensive_movie_data cmd
WHERE 
    cmd.total_cast > 5
    AND cmd.avg_directors > 0.5
    AND cmd.first_year BETWEEN 1900 AND 2000
ORDER BY 
    cmd.last_year DESC
LIMIT 10;
