WITH RECURSIVE popular_movies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
movie_details AS (
    SELECT 
        pm.movie_id,
        pm.title,
        pm.production_year,
        COALESCE(mci.company_count, 0) AS company_count,
        COALESCE(mk.keyword_count, 0) AS keyword_count
    FROM 
        popular_movies pm
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(DISTINCT company_id) AS company_count
        FROM 
            movie_companies
        GROUP BY movie_id
    ) mci ON pm.movie_id = mci.movie_id
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(DISTINCT keyword_id) AS keyword_count
        FROM 
            movie_keyword
        GROUP BY movie_id
    ) mk ON pm.movie_id = mk.movie_id
),
ranked_movies AS (
    SELECT 
        md.*,
        RANK() OVER (ORDER BY (company_count + keyword_count) DESC) AS movie_rank
    FROM 
        movie_details md
)
SELECT 
    rm.title,
    rm.production_year,
    rm.company_count,
    rm.keyword_count,
    CASE 
        WHEN rm.movie_rank <= 10 THEN 'Top 10'
        WHEN rm.movie_rank <= 50 THEN 'Top 50'
        ELSE 'Others'
    END AS rank_category
FROM 
    ranked_movies rm
WHERE 
    rm.company_count IS NOT NULL
    AND rm.keyword_count > 2
ORDER BY 
    rm.movie_rank;
