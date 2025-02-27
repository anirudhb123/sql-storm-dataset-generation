WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank_year
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        COALESCE(STRING_AGG(DISTINCT cn.name, ', '), 'No Companies') AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_cast,
        SUM(CASE WHEN p.gender = 'M' THEN 1 ELSE 0 END) AS male_cast,
        COUNT(ci.id) AS total_cast
    FROM cast_info ci
    JOIN aka_name p ON ci.person_id = p.person_id
    GROUP BY ci.movie_id
),
final_results AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mk.keywords,
        ci.company_names,
        cd.female_cast,
        cd.male_cast,
        cd.total_cast,
        CASE 
            WHEN cd.total_cast > 0 THEN ROUND((cd.female_cast::DECIMAL / cd.total_cast) * 100, 2)
            ELSE NULL 
        END AS female_ratio
    FROM ranked_movies rm
    LEFT JOIN movie_keywords mk ON rm.movie_id = mk.movie_id
    LEFT JOIN company_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN cast_details cd ON rm.movie_id = cd.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    keywords,
    company_names,
    female_cast,
    male_cast,
    total_cast,
    COALESCE(female_ratio, 0) AS female_ratio_percentage
FROM final_results
WHERE production_year BETWEEN 2000 AND 2023
ORDER BY production_year ASC, title DESC
LIMIT 100;
