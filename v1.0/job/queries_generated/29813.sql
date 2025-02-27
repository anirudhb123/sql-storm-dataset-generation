WITH base_movie_info AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM title m
        JOIN aka_title at ON m.id = at.movie_id
        JOIN cast_info ca ON m.id = ca.movie_id
    WHERE m.production_year BETWEEN 2000 AND 2020
    GROUP BY m.id, m.title, m.production_year
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_companies_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM movie_companies mc
        JOIN company_name co ON mc.company_id = co.id
    GROUP BY mc.movie_id
),
full_movie_info AS (
    SELECT 
        b.movie_id,
        b.title,
        b.production_year,
        b.cast_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(mci.companies, 'No Companies') AS companies
    FROM base_movie_info b
        LEFT JOIN movie_keywords mk ON b.movie_id = mk.movie_id
        LEFT JOIN movie_companies_info mci ON b.movie_id = mci.movie_id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    f.keywords,
    f.companies
FROM full_movie_info f
WHERE f.cast_count > 5
ORDER BY f.production_year DESC, f.cast_count DESC
LIMIT 10;
