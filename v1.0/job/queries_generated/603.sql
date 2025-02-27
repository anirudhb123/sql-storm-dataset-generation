WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
),
cast_stats AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY ci.movie_id
),
company_stats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    r.movie_id,
    r.movie_title,
    r.production_year,
    COALESCE(cs.cast_count, 0) AS total_cast,
    COALESCE(cs.cast_names, 'No Cast') AS cast_information,
    COALESCE(co.company_count, 0) AS total_companies,
    COALESCE(co.company_names, 'No Companies') AS companies_information
FROM ranked_movies r
LEFT JOIN cast_stats cs ON r.movie_id = cs.movie_id
LEFT JOIN company_stats co ON r.movie_id = co.movie_id
WHERE r.year_rank <= 5
ORDER BY r.production_year DESC, r.movie_title ASC;
