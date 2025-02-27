WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        k.keyword,
        COALESCE(SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = a.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        cast_info c ON c.movie_id = a.id
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword,
        rm.cast_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.rn = 1 AND rm.cast_count > 10  -- Movies with more than 10 cast members
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.keyword,
    CONCAT('Total Cast Members: ', f.cast_count) AS cast_info,
    STRING_AGG(DISTINCT c.name, ', ') AS cast_names
FROM 
    filtered_movies f
JOIN 
    complete_cast cc ON cc.movie_id = f.movie_id
JOIN 
    name c ON c.id = cc.subject_id
GROUP BY 
    f.movie_id, f.title, f.production_year, f.keyword, f.cast_count
ORDER BY 
    f.production_year DESC, f.title;
