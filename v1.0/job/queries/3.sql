WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        rk.rank AS rating_rank,
        COUNT(DISTINCT mc.company_id) AS production_companies_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON a.movie_id = mc.movie_id
    LEFT JOIN 
        (SELECT 
            movie_id, 
            ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY info_type_id) AS rank
         FROM 
            movie_info
         WHERE 
            LOWER(info) LIKE '%action%'
        ) rk ON a.movie_id = rk.movie_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.title, a.production_year, rk.rank
),
average_rank AS (
    SELECT 
        AVG(rating_rank) AS avg_rating
    FROM 
        ranked_movies
    WHERE 
        rating_rank IS NOT NULL
),
final_result AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.rating_rank,
        rm.production_companies_count,
        CASE 
            WHEN rm.rating_rank < ar.avg_rating THEN 'Below Average'
            WHEN rm.rating_rank = ar.avg_rating THEN 'Average'
            ELSE 'Above Average'
        END AS rating_comparison
    FROM 
        ranked_movies rm
    CROSS JOIN 
        average_rank ar
)
SELECT 
    title, 
    production_year, 
    rating_rank, 
    production_companies_count, 
    rating_comparison
FROM 
    final_result
WHERE 
    production_companies_count > 2
ORDER BY 
    production_year DESC, rating_rank ASC;
