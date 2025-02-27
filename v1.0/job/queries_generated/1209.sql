WITH movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS special_notes_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    LEFT JOIN 
        company_name cn ON cn.imdb_id = t.id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = t.id
    GROUP BY 
        t.title, t.production_year
),
keyword_stats AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
ranked_movies AS (
    SELECT 
        md.title,
        md.production_year,
        md.cast_count,
        md.special_notes_count,
        ks.keywords,
        RANK() OVER (ORDER BY md.production_year DESC, md.cast_count DESC) AS ranking
    FROM 
        movie_details md
    LEFT JOIN 
        keyword_stats ks ON ks.movie_id = md.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.special_notes_count,
    rm.keywords,
    CASE 
        WHEN rm.cast_count > 10 THEN 'Large Cast'
        WHEN rm.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    ranked_movies rm
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.ranking ASC, rm.title;
