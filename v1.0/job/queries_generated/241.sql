WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
movie_details AS (
    SELECT 
        a.id AS movie_id,
        a.title AS title,
        a.production_year,
        COALESCE(mk.keyword_list, 'No Keywords') AS keywords
    FROM 
        aka_title a
    LEFT JOIN (
        SELECT 
            movie_id,
            STRING_AGG(k.keyword, ', ') AS keyword_list
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) mk ON a.id = mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    COALESCE(rm.cast_count, 0) AS cast_count,
    CASE 
        WHEN rm.rank IS NULL THEN 'Not Ranked' 
        ELSE CAST(rm.rank AS TEXT) 
    END AS rank
FROM 
    movie_details md
LEFT JOIN 
    ranked_movies rm ON md.movie_id = rm.movie_title
WHERE 
    md.production_year BETWEEN 2000 AND 2020
    AND (
        md.keywords IS NOT NULL 
        OR EXISTS (
            SELECT 1 
            FROM movie_info mi 
            WHERE mi.movie_id = md.movie_id 
            AND mi.note IS NOT NULL
        )
    )
ORDER BY 
    md.production_year ASC, 
    cast_count DESC;
