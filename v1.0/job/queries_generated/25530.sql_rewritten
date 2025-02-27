WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year > 2000  
    GROUP BY 
        t.id, t.title, t.production_year
),
movies_with_keywords AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.cast_count,
        r.cast_names,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        ranked_movies r
    LEFT JOIN 
        movie_keyword mk ON r.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        r.movie_id, r.title, r.production_year, r.cast_count, r.cast_names
),
final_benchmark AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.production_year,
        mwk.cast_count,
        mwk.cast_names,
        mwk.keywords,
        CASE 
            WHEN mwk.cast_count > 5 THEN 'High'
            WHEN mwk.cast_count BETWEEN 3 AND 5 THEN 'Medium'
            ELSE 'Low'
        END AS cast_size_category
    FROM 
        movies_with_keywords mwk
)
SELECT 
    fb.movie_id,
    fb.title,
    fb.production_year,
    fb.cast_count,
    fb.cast_names,
    fb.keywords,
    fb.cast_size_category
FROM 
    final_benchmark fb
ORDER BY 
    fb.production_year DESC, 
    fb.cast_count DESC
LIMIT 100;