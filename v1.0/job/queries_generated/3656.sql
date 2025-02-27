WITH movie_details AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id
), ranked_movies AS (
    SELECT 
        md.*,
        RANK() OVER (ORDER BY md.production_year DESC, md.cast_count DESC) AS rank
    FROM 
        movie_details md
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(rm.companies, 'Unknown') AS companies,
    rm.cast_count,
    (SELECT 
        COUNT(DISTINCT mk.keyword_id) 
     FROM 
        movie_keyword mk 
     WHERE 
        mk.movie_id = rm.movie_id) AS keyword_count
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 10
    AND rm.production_year IS NOT NULL
    AND (rm.cast_count IS NOT NULL OR rm.companies IS NOT NULL)
ORDER BY 
    rm.rank;
