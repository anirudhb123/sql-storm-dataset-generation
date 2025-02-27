WITH movie_details AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM 
        aka_title mt 
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id 
    JOIN 
        cast_info ci ON cc.subject_id = ci.id 
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id 
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id 
    GROUP BY 
        mt.id
),
keyword_aggregation AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
ranked_movies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.cast_names,
        md.production_company_count,
        COALESCE(kg.keywords, 'No Keywords Found') AS keywords,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.production_company_count DESC) AS rank
    FROM 
        movie_details md
    LEFT JOIN 
        keyword_aggregation kg ON md.movie_title = kg.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_names,
    rm.production_company_count,
    rm.keywords
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.production_company_count DESC;
