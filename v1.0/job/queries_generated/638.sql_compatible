
WITH ranked_movies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
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
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(ci.companies, 'No Companies') AS companies
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keywords mk ON rm.movie_title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
LEFT JOIN 
    company_info ci ON rm.movie_title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
WHERE 
    rm.rank_by_cast <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
