
WITH RECURSIVE ranked_movies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS rn
    FROM aka_title at
    LEFT JOIN cast_info ci ON at.movie_id = ci.movie_id
    WHERE at.production_year BETWEEN 2000 AND 2023
    GROUP BY at.id, at.title, at.production_year
),
character_names AS (
    SELECT 
        cn.id AS char_id,
        cn.name,
        ROW_NUMBER() OVER (ORDER BY cn.name) AS char_rank
    FROM char_name cn
    WHERE cn.name IS NOT NULL AND cn.name <> ''
),
keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movies_with_keywords AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        COALESCE(k.keyword_list, '') AS keywords,
        rm.cast_count,
        CASE 
            WHEN rm.cast_count > 10 THEN 'Large Cast'
            WHEN rm.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END AS cast_size_category
    FROM ranked_movies rm
    LEFT JOIN keywords k ON rm.title_id = k.movie_id
),
distinct_producer_info AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS producers
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Producer')
    GROUP BY mc.movie_id
)

SELECT 
    mwk.title,
    mwk.production_year,
    mwk.keywords,
    mwk.cast_size_category,
    dp.producers
FROM movies_with_keywords mwk
LEFT JOIN distinct_producer_info dp ON mwk.title_id = dp.movie_id
WHERE mwk.cast_size_category <> 'Small Cast'
ORDER BY mwk.production_year DESC, mwk.cast_count DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
