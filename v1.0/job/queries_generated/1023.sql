WITH movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.nr_order) AS cast_list,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id
),
top_movies AS (
    SELECT 
        md.title,
        md.production_year,
        md.cast_list,
        md.keyword_count,
        DENSE_RANK() OVER (ORDER BY md.keyword_count DESC) AS rank
    FROM 
        movie_details md
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.cast_list, 'No Cast Available') AS cast_list,
    CASE 
        WHEN tm.keyword_count >= 5 THEN 'Popular'
        WHEN tm.keyword_count BETWEEN 1 AND 4 THEN 'Moderately Popular'
        ELSE 'Not Popular'
    END AS popularity,
    nt.info AS additional_info
FROM 
    top_movies tm
LEFT JOIN 
    movie_info mi ON tm.title = mi.info 
LEFT JOIN 
    info_type nt ON mi.info_type_id = nt.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank, tm.production_year DESC;
