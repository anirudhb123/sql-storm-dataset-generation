WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.id) AS year_rank,
        MAX(CASE WHEN k.keyword = 'Action' THEN 1 ELSE 0 END) AS is_action,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        a.id, a.title, a.production_year
),
filtered_movies AS (
    SELECT 
        r.title,
        r.production_year,
        r.year_rank,
        r.is_action,
        r.cast_count
    FROM 
        ranked_movies r
    WHERE 
        r.cast_count > 5 AND 
        r.production_year BETWEEN 2000 AND 2020
)
SELECT 
    f.title,
    f.production_year,
    COALESCE(f.year_rank, 'Not Ranked') AS year_rank,
    CASE 
        WHEN f.is_action = 1 THEN 'Action Movie' 
        ELSE 'Not an Action Movie' 
    END AS movie_type
FROM 
    filtered_movies f
ORDER BY 
    f.production_year DESC, 
    f.title;
