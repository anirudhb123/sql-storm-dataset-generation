WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(COUNT(DISTINCT c.person_id), 0) AS total_cast,
        COALESCE(GROUP_CONCAT(DISTINCT a.name), 'No actors') AS cast_list,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id
),
filter_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.cast_list
    FROM 
        ranked_movies rm
    WHERE 
        rm.production_year BETWEEN 2000 AND 2023
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.total_cast,
    fm.cast_list,
    COUNT(DISTINCT mk.keyword) AS total_keywords,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
FROM 
    filter_movies fm
LEFT JOIN 
    movie_keyword mk ON fm.movie_id = mk.movie_id
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, fm.total_cast, fm.cast_list
ORDER BY 
    fm.production_year DESC, fm.total_cast DESC;
