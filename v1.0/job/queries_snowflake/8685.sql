
WITH ranked_movies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        AVG(LENGTH(mi.info)) AS avg_movie_info_length
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.title, t.production_year
), movie_rankings AS (
    SELECT 
        movie_title,
        production_year,
        company_count,
        avg_movie_info_length,
        RANK() OVER (ORDER BY company_count DESC, avg_movie_info_length DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    mr.movie_title,
    mr.production_year,
    mr.company_count,
    mr.avg_movie_info_length,
    r.role AS top_role
FROM 
    movie_rankings mr
LEFT JOIN 
    cast_info ci ON mr.movie_title = ci.movie_id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    mr.rank <= 10
ORDER BY 
    mr.rank;
