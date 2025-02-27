WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(mk.keyword_id) DESC) AS rank
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY t.id
), FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.keyword_count,
        rm.cast_count
    FROM RankedMovies rm
    WHERE rm.rank <= 5
), CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.keyword_count,
    fm.cast_count,
    ci.companies
FROM FilteredMovies fm
LEFT JOIN CompanyInfo ci ON fm.id = ci.movie_id
ORDER BY fm.production_year, fm.keyword_count DESC;
