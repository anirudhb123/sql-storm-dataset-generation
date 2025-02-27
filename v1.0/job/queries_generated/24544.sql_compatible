
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(ci.id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        cn.country_code IS NOT NULL
),

movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        rm.cast_count,
        CASE 
            WHEN rm.cast_count > 5 THEN 'Ensemble Cast'
            WHEN rm.cast_count IS NULL THEN 'No Cast Info'
            ELSE 'Small Cast'
        END AS cast_description
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_keywords mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.year_rank <= 5
)

SELECT 
    md.movie_id, 
    md.title, 
    md.production_year, 
    md.keywords,
    md.cast_count,
    md.cast_description,
    COUNT(DISTINCT ci.person_id) AS unique_actors,
    AVG(CASE 
            WHEN ci.nr_order IS NOT NULL THEN ci.nr_order 
            ELSE 0 
        END) AS avg_order
FROM 
    movie_details md
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.keywords, md.cast_count, md.cast_description
ORDER BY 
    md.production_year DESC, unique_actors DESC
LIMIT 10;
