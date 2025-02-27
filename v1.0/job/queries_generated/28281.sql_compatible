
WITH relevant_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND cn.country_code = 'USA'
    GROUP BY 
        t.id, t.title, t.production_year
),
keyword_aggregate AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
final_benchmark AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.roles,
        ka.keywords_list
    FROM 
        relevant_movies rm
    LEFT JOIN 
        keyword_aggregate ka ON rm.movie_id = ka.movie_id
)
SELECT 
    fb.title,
    fb.production_year,
    fb.total_cast,
    fb.roles,
    COALESCE(fb.keywords_list, 'No keywords') AS keywords
FROM 
    final_benchmark fb
ORDER BY 
    fb.production_year DESC, 
    fb.total_cast DESC
LIMIT 50;
