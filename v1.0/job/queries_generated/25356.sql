WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')'), ', ') AS full_cast,
        k.keyword AS main_keyword
    FROM 
        title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info c ON c.movie_id = t.id
    JOIN 
        role_type r ON r.id = c.person_role_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
), 
filtered_movies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year,
        rm.cast_count,
        rm.full_cast,
        rm.main_keyword
    FROM 
        ranked_movies rm
    WHERE 
        rm.production_year >= 2000 
        AND rm.cast_count > 5
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    f.full_cast,
    COALESCE(f.main_keyword, 'N/A') AS main_keyword
FROM 
    filtered_movies f
ORDER BY 
    f.production_year DESC, 
    f.cast_count DESC
LIMIT 10;
