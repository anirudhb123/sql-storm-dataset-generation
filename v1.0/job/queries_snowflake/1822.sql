WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY MAX(mk.id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        ranked_movies rm
    WHERE 
        rm.rn = 1
),
avg_casts AS (
    SELECT 
        mc.movie_id,
        AVG(CASE 
            WHEN ci.note IS NOT NULL THEN 1 
            ELSE 0 
        END) AS avg_cast_count
    FROM 
        complete_cast mc
    LEFT JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    ac.avg_cast_count,
    COALESCE((SELECT COUNT(*) 
              FROM movie_info mi 
              WHERE mi.movie_id = tm.movie_id 
              AND mi.note IS NOT NULL), 0) AS info_count
FROM 
    top_movies tm
LEFT JOIN 
    avg_casts ac ON tm.movie_id = ac.movie_id
WHERE 
    tm.production_year BETWEEN 2000 AND 2020
ORDER BY 
    tm.production_year DESC, info_count DESC;
