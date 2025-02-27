WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS year_rank
    FROM aka_title a
    JOIN cast_info c ON a.id = c.movie_id
    WHERE a.production_year IS NOT NULL
    GROUP BY a.id, a.title, a.production_year
),
HighCastMovies AS (
    SELECT 
        title, 
        production_year, 
        cast_count
    FROM RankedMovies
    WHERE year_rank <= 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT 
    hcm.title,
    hcm.production_year,
    hcm.cast_count,
    ci.companies,
    ci.company_types
FROM HighCastMovies hcm
LEFT JOIN CompanyInfo ci ON hcm.production_year = (
    SELECT MAX(production_year) 
    FROM title 
    WHERE id IN (SELECT movie_id FROM complete_cast WHERE subject_id IN (SELECT person_id FROM aka_name WHERE name LIKE '%Smith%'))
)
ORDER BY hcm.production_year DESC, hcm.cast_count DESC;
