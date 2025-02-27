WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_in_year,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON ci.movie_id = a.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = a.id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        rank_in_year,
        keyword_count
    FROM 
        RankedMovies
    WHERE 
        rank_in_year <= 5
)
SELECT 
    tm.title, 
    tm.production_year,
    COALESCE(ci.role_id, -1) AS role_id,
    COALESCE(mk.keyword, 'No Keyword') AS movie_keyword,
    CASE 
        WHEN tm.keyword_count = 0 THEN 'No Keywords'
        ELSE 'Has Keywords'
    END AS keyword_status,
    COUNT(DISTINCT c.name) AS unique_cast_names
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id LIMIT 1)
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
LEFT JOIN 
    aka_name c ON c.person_id = ci.person_id
GROUP BY 
    tm.title, tm.production_year, ci.role_id, mk.keyword, tm.keyword_count
HAVING 
    COUNT(DISTINCT c.name) > 2 OR 
    tm.keyword_count = 0
ORDER BY 
    tm.production_year DESC, 
    unique_cast_names DESC
LIMIT 10;

-- The query retrieves the top 5 movies by cast count for each production year, 
-- checking for uniqueness of cast names, handling NULL cases with COALESCE, 
-- and utilizing window functions for ranking. It further validates the presence 
-- of keywords and captures the bizarre corner case of having no keywords.
