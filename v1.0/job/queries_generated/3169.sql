WITH ranked_movies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title) AS rank
    FROM aka_title at
    WHERE at.production_year >= 2000
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(*) AS role_count
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id, rt.role
),
movie_keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_info AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE cn.country_code IS NOT NULL
),
combined_data AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cr.role,
        cr.role_count,
        mkc.keyword_count,
        ci.company_name,
        ci.company_type
    FROM ranked_movies rm
    LEFT JOIN cast_roles cr ON rm.movie_id = cr.movie_id
    LEFT JOIN movie_keyword_counts mkc ON rm.movie_id = mkc.movie_id
    LEFT JOIN company_info ci ON rm.movie_id = ci.movie_id
)
SELECT 
    cd.movie_id,
    cd.title,
    cd.production_year,
    COALESCE(cd.role, 'Unknown') AS role,
    COALESCE(cd.role_count, 0) AS role_count,
    COALESCE(cd.keyword_count, 0) AS keyword_count,
    COALESCE(cd.company_name, 'Independent') AS company_name,
    COALESCE(cd.company_type, 'Unknown') AS company_type
FROM combined_data cd
WHERE cd.keyword_count > 2 
  AND (cd.role_count IS NULL OR cd.role_count > 1)
ORDER BY cd.production_year DESC, cd.title;
