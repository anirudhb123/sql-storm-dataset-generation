WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS director_name,
        COUNT(DISTINCT m.id) AS company_count
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id 
    JOIN 
        aka_name a ON ci.person_id = a.person_id 
    JOIN 
        movie_companies mc ON t.id = mc.movie_id 
    JOIN 
        company_name cn ON mc.company_id = cn.id 
    WHERE 
        ci.person_role_id IN (SELECT id FROM role_type WHERE role = 'Director')
    GROUP BY 
        t.id, a.name
),
keyword_count AS (
    SELECT
        m.movie_id,
        COUNT(k.id) AS keyword_count
    FROM 
        movie_keyword m 
    JOIN 
        keyword k ON m.keyword_id = k.id 
    GROUP BY 
        m.movie_id
), 
selected_movies AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        r.director_name,
        r.company_count,
        COALESCE(kc.keyword_count, 0) AS keyword_count
    FROM 
        ranked_titles r
    LEFT JOIN 
        keyword_count kc ON r.title_id = kc.movie_id
),
final_results AS (
    SELECT 
        movie.*,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = movie.title_id) AS cast_count
    FROM    
        selected_movies movie
    WHERE 
        movie.production_year >= 2000
    ORDER BY 
        movie.production_year DESC, 
        movie.title ASC
)
SELECT 
    title,
    production_year,
    director_name,
    company_count,
    keyword_count,
    cast_count
FROM 
    final_results
LIMIT 10;
