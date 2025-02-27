WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY ki.keyword) AS keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    WHERE 
        t.production_year > 2000
),
movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(COUNT(ci.id), 0) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        ranked_movies rm
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
top_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.cast_names,
        RANK() OVER (ORDER BY md.cast_count DESC) AS rank_count
    FROM 
        movie_details md
    WHERE 
        md.cast_count > 0
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.cast_names,
    (SELECT COUNT(*) FROM top_movies WHERE rank_count <= 10) AS top_movies_count,
    NULLIF(tm.production_year - (SELECT MIN(production_year) FROM top_movies), 0) AS year_difference
FROM 
    top_movies tm
WHERE 
    tm.rank_count <= 10
ORDER BY 
    tm.cast_count DESC, tm.production_year DESC;
