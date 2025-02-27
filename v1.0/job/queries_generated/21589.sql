WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank,
        CAST(m.info AS VARCHAR) AS movie_info,
        COALESCE(GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword), 'No keywords') AS keywords,
        COALESCE(c.name, 'Unknown Company') AS company_name
    FROM aka_title a
    LEFT JOIN movie_info m ON a.id = m.movie_id
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    WHERE a.production_year IS NOT NULL
    GROUP BY a.title, a.production_year, m.info, c.name
),
filtered_movies AS (
    SELECT 
        movie_title, 
        production_year, 
        movie_info,
        keywords,
        company_name
    FROM ranked_movies
    WHERE rank <= 3
    AND production_year BETWEEN 2000 AND 2020
    AND movie_info NOT LIKE '%unrated%'
),
final_result AS (
    SELECT 
        f.movie_title,
        f.production_year,
        f.keywords,
        f.company_name,
        CASE 
            WHEN f.keywords IS NULL THEN 'No Keywords'
            ELSE f.keywords
        END AS keyword_status
    FROM filtered_movies f
    LEFT JOIN (SELECT DISTINCT movie_title FROM filtered_movies) sub ON f.movie_title = sub.movie_title
)

SELECT 
    movie_title,
    production_year,
    keywords,
    company_name,
    keyword_status
FROM final_result
ORDER BY production_year DESC, movie_title
LIMIT 50;

