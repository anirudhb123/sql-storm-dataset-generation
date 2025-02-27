
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ARRAY_AGG(DISTINCT a.name) AS cast_names
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
final_summary AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        ks.keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        keyword_summary ks ON rm.movie_id = ks.movie_id
    ORDER BY 
        rm.production_year DESC
)
SELECT 
    fs.movie_id,
    fs.title,
    fs.production_year,
    fs.cast_count,
    fs.cast_names,
    COALESCE(fs.keywords, ARRAY[]::text[]) AS keywords_list
FROM 
    final_summary fs
WHERE 
    fs.cast_count > 5
LIMIT 10;
