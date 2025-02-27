WITH ranked_movies AS (
    SELECT 
        mt.title,
        mt.production_year,
        mt.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC, mt.title ASC) AS year_rank,
        RANK() OVER (ORDER BY mt.production_year DESC, LENGTH(mt.title) DESC) AS title_length_rank
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
),
cast_performance AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS unique_cast_count,
        SUM(CASE WHEN r.role = 'star' THEN 1 ELSE 0 END) AS star_count
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY ci.movie_id
),
null_benchmarks AS (
    SELECT 
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM keyword k
    LEFT JOIN movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY k.keyword
    HAVING COUNT(mk.id) < 2
),
companies AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE cn.country_code IS NOT NULL
    GROUP BY mc.movie_id
)
SELECT 
    r.title,
    r.production_year,
    cp.unique_cast_count,
    cp.star_count,
    cb.company_names,
    nb.keyword,
    nb.keyword_count,
    CASE 
        WHEN cp.star_count IS NULL THEN 'N/A'
        ELSE CAST(cp.star_count AS VARCHAR)
    END AS star_count_display,
    CASE 
        WHEN r.year_rank <= 5 AND cb.company_names IS NOT NULL THEN 'Top Movies with Companies'
        WHEN nb.keyword_count > 1 THEN 'Frequent Keywords'
        ELSE 'Other Movies'
    END AS classification
FROM ranked_movies r
LEFT JOIN cast_performance cp ON r.movie_id = cp.movie_id
LEFT JOIN companies cb ON r.movie_id = cb.movie_id
LEFT JOIN null_benchmarks nb ON r.production_year = nb.keyword_count
WHERE r.year_rank <= 10
ORDER BY r.production_year DESC, cp.star_count DESC NULLS LAST, r.title;

