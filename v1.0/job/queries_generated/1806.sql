WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title ASC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
movie_details AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COALESCE(MAX(ci.nr_order), 0) AS max_cast_order,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        ranked_movies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year
),
filtered_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.max_cast_order,
        md.cast_count
    FROM 
        movie_details md
    WHERE 
        md.cast_count > 5 
        AND md.production_year BETWEEN 2000 AND 2023
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.keywords,
    fm.max_cast_order,
    fm.cast_count,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = fm.movie_id AND mi.info_type_id = 1) AS info_count,
    (SELECT STRING_AGG(DISTINCT p.info, ', ') FROM person_info p WHERE p.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = fm.movie_id)) AS cast_info_summary
FROM 
    filtered_movies fm
ORDER BY 
    fm.production_year DESC, 
    fm.title ASC
LIMIT 50;
